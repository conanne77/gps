------------------------------------------------------------------------------
--                                  G P S                                   --
--                                                                          --
--                     Copyright (C) 2003-2013, AdaCore                     --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- COPYING3.  If not, go to http://www.gnu.org/licenses for a complete copy --
-- of the license.                                                          --
------------------------------------------------------------------------------

with Ada.Containers;
with Ada.Unchecked_Conversion;

with GNATCOLL.Projects;              use GNATCOLL.Projects;
with GNATCOLL.Python;                use GNATCOLL.Python;
with GNATCOLL.Scripts;               use GNATCOLL.Scripts;
with GNATCOLL.Scripts.Python;        use GNATCOLL.Scripts.Python;
with GNATCOLL.Scripts.Python.Gtkada; use GNATCOLL.Scripts.Python.Gtkada;
with GNATCOLL.Xref;

with Basic_Types;

with Glib.Object;                use Glib.Object;
with Gtk.Enums;                  use Gtk.Enums;
with Gtk.Widget;                 use Gtk.Widget;
with Gtkada.MDI;                 use Gtkada.MDI;

with Generic_Views;
with GPS.Intl;                   use GPS.Intl;
with GPS.Kernel.Custom;          use GPS.Kernel.Custom;
with GPS.Kernel.MDI;             use GPS.Kernel.MDI;
with GPS.Kernel.Modules;         use GPS.Kernel.Modules;
with GPS.Kernel.Preferences;     use GPS.Kernel.Preferences;
with GPS.Kernel.Scripts;         use GPS.Kernel.Scripts;
with GPS.Kernel;                 use GPS.Kernel;
with GPS.Python_Core;
with GPS.Main_Window;            use GPS.Main_Window;
with Histories;                  use Histories;
with Interactive_Consoles;       use Interactive_Consoles;
with String_Utils;               use String_Utils;
with System;
with Traces;                     use Traces;
with GNATCOLL.VFS;               use GNATCOLL.VFS;
with XML_Utils;                  use XML_Utils;
with Xref;                       use Xref;

package body Python_Module is
   use type GNATCOLL.Xref.Visible_Column;

   Me  : constant Debug_Handle := Create ("Python_Module");

   type Hash_Index is range 0 .. 100000;
   function Hash is new String_Utils.Hash (Hash_Index);

   type Python_Module_Record is new Module_ID_Record with null record;
   overriding procedure Destroy (Module : in out Python_Module_Record);

   procedure Load_Dir
     (Kernel             : access GPS.Kernel.Kernel_Handle_Record'Class;
      Dir                : Virtual_File;
      Default_Autoload   : Boolean;
      Ignore_User_Config : Boolean);
   --  Load all .py files from Dir, if any.
   --  Default_Autoload indicates whether scripts in this directory should
   --  be autoloaded by default, unless otherwise mentioned in
   --  ~/.gps/startup.xml
   --  Ignore_User_Config should be True for the support scripts that are not
   --  user-configurable plugins.

   type Python_Console_Record is new Interactive_Console_Record
     with null record;

   function Initialize
     (Console : access Python_Console_Record'Class) return Gtk_Widget;
   --  Initialize the python console, and returns the focus widget.

   package Python_Views is new Generic_Views.Simple_Views
     (Module_Name        => "Python_Console",
      View_Name          => -"Python",
      Formal_View_Record => Python_Console_Record,
      Formal_MDI_Child   => GPS_Console_MDI_Child_Record,
      Reuse_If_Exist     => True,
      Initialize         => Initialize,
      Local_Toolbar      => False,
      Local_Config       => False,
      Areas              => Gtkada.MDI.Sides_Only,
      Group              => Group_Consoles);

   procedure Python_File_Command_Handler
     (Data : in out Callback_Data'Class; Command : String);
   procedure Python_GUI_Command_Handler
     (Data : in out Callback_Data'Class; Command : String);
   procedure Python_Project_Command_Handler
     (Data : in out Callback_Data'Class; Command : String);
   procedure Python_Entity_Command_Handler
     (Data : in out Callback_Data'Class; Command : String);
   procedure Python_Location_Command_Handler
     (Data : in out Callback_Data'Class; Command : String);
   --  Handler for the commands related to the various classes

   type Python_MDI_Child_Record is new GPS_MDI_Child_Record with record
      Save_Desktop : Subprogram_Type;
   end record;
   type Python_MDI_Child is access all Python_MDI_Child_Record'Class;
   overriding function Save_Desktop
     (Self : not null access Python_MDI_Child_Record)
      return XML_Utils.Node_Ptr;
   --  An Ada wrapper for a view created in Python

   ----------------
   -- Initialize --
   ----------------

   function Initialize
     (Console : access Python_Console_Record'Class) return Gtk_Widget
   is
      Backend : Virtual_Console;
      Script  : constant Scripting_Language :=
                  Lookup_Scripting_Language
                    (Get_Scripts (Console.Kernel), Python_Name);
      Errors  : aliased Boolean;
      Result  : PyObject;

      Hist : constant History_Key := "python_console";
   begin
      Interactive_Consoles.Initialize
        (Console, Prompt => "", Handler => Default_Command_Handler'Access,
         User_Data       => System.Null_Address,
         History_List    => Get_History (Console.Kernel),
         Wrap_Mode       => Wrap_Char,
         Key             => Hist);
      Set_Font_And_Colors (Console.Get_View, Fixed_Font => True);
      Set_Max_Length   (Get_History (Console.Kernel).all, 100, Hist);
      Allow_Duplicates (Get_History (Console.Kernel).all, Hist, True, True);

      Backend := Get_Or_Create_Virtual_Console (Console);
      Set_Default_Console (Script, Backend);

      --  After creating the Python console, import everything from
      --  the plugin GPS_help, to override the default help function

      Console.Enable_Prompt_Display (False);
      Result := Run_Command
        (Python_Scripting (Script),
         "import GPS_help ; help = GPS_help.help",
         Need_Output     => False,
         Console         => Backend,
         Show_Command    => False,
         Hide_Output     => True,
         Hide_Exceptions => True,
         Errors          => Errors'Unchecked_Access);
      Py_XDECREF (Result);
      Console.Enable_Prompt_Display (True);
      Console.Display_Prompt;

      return Gtk_Widget (Console.Get_View);
   end Initialize;

   ---------------------
   -- Register_Module --
   ---------------------

   procedure Register_Module
     (Kernel : access GPS.Kernel.Kernel_Handle_Record'Class)
   is
      Ignored : Integer;
      Tmp     : Boolean;
      pragma Unreferenced (Ignored, Tmp);
      Script  : Scripting_Language;
      MDI     : Class_Type;

   begin
      GPS.Python_Core.Register_Python (Kernel);

      Script := Lookup_Scripting_Language (Get_Scripts (Kernel), Python_Name);
      if Script = null then
         Trace (Me, "Python not supported");
         return;
      end if;

      Init_PyGtk_Support (Script);

      Set_Default_Console (Script, Kernel.Get_Messages_Window);

      Python_Views.Register_Module
        (Kernel,
         new Python_Module_Record,
         Menu_Name  => -"Consoles/_Python");

      MDI := New_Class (Get_Scripts (Kernel), "MDI");

      Add_PyWidget_Method
        (Get_Scripts (Kernel), Class => Get_GUI_Class (Kernel));
      Register_Command
        (Get_Scripts (Kernel),
         Command       => "add",
         Handler       => Python_GUI_Command_Handler'Access,
         Class         => MDI,
         Params        =>
            (Param ("widget"),
             Param ("title", Optional => True),
             Param ("short", Optional => True),
             Param ("group", Optional => True),
             Param ("position", Optional => True),
             Param ("save_desktop", Optional => True)),
         Static_Method => True,
         Language      => Python_Name);

      --  Change the screen representation of the various classes. This way,
      --  commands can return classes, but still displayed user-readable
      --  strings.
      --  Also make sure these can be used as keys in dictionaries.

      Register_Command
        (Get_Scripts (Kernel),
         Command      => "__str__",
         Handler      => Python_File_Command_Handler'Access,
         Class        => Get_File_Class (Kernel),
         Language     => Python_Name);
      Register_Command
        (Get_Scripts (Kernel),
         Command      => "__repr__",
         Handler      => Python_File_Command_Handler'Access,
         Class        => Get_File_Class (Kernel),
         Language     => Python_Name);
      Register_Command
        (Get_Scripts (Kernel),
         Command      => "__hash__",
         Handler      => Python_File_Command_Handler'Access,
         Class        => Get_File_Class (Kernel),
         Language     => Python_Name);
      Register_Command
        (Get_Scripts (Kernel),
         Command      => "__cmp__",
         Minimum_Args => 1,
         Maximum_Args => 1,
         Handler      => Python_File_Command_Handler'Access,
         Class        => Get_File_Class (Kernel),
         Language     => Python_Name);

      Register_Command
        (Get_Scripts (Kernel),
         Command      => "__str__",
         Handler      => Python_Project_Command_Handler'Access,
         Class        => Get_Project_Class (Kernel),
         Language      => Python_Name);
      Register_Command
        (Get_Scripts (Kernel),
         Command      => "__repr__",
         Handler      => Python_Project_Command_Handler'Access,
         Class        => Get_Project_Class (Kernel),
         Language     => Python_Name);
      Register_Command
        (Get_Scripts (Kernel),
         Command      => "__hash__",
         Handler      => Python_Project_Command_Handler'Access,
         Class        => Get_Project_Class (Kernel),
         Language     => Python_Name);
      Register_Command
        (Get_Scripts (Kernel),
         Command      => "__cmp__",
         Minimum_Args => 1,
         Maximum_Args => 1,
         Handler      => Python_Project_Command_Handler'Access,
         Class        => Get_Project_Class (Kernel),
         Language     => Python_Name);

      Register_Command
        (Get_Scripts (Kernel),
         Command      => "__str__",
         Handler      => Python_Entity_Command_Handler'Access,
         Class        => Get_Entity_Class (Kernel),
         Language     => Python_Name);
      Register_Command
        (Get_Scripts (Kernel),
         Command      => "__repr__",
         Handler      => Python_Entity_Command_Handler'Access,
         Class        => Get_Entity_Class (Kernel),
         Language     => Python_Name);
      Register_Command
        (Get_Scripts (Kernel),
         Command      => "__hash__",
         Handler      => Python_Entity_Command_Handler'Access,
         Class        => Get_Entity_Class (Kernel),
         Language     => Python_Name);
      Register_Command
        (Get_Scripts (Kernel),
         Command      => "__cmp__",
         Minimum_Args => 1,
         Maximum_Args => 1,
         Handler      => Python_Entity_Command_Handler'Access,
         Class        => Get_Entity_Class (Kernel),
         Language     => Python_Name);

      Register_Command
        (Get_Scripts (Kernel),
         Command      => "__str__",
         Handler      => Python_Location_Command_Handler'Access,
         Class        => Get_File_Location_Class (Kernel),
         Language     => Python_Name);
      Register_Command
        (Get_Scripts (Kernel),
         Command      => "__repr__",
         Handler      => Python_Location_Command_Handler'Access,
         Class        => Get_File_Location_Class (Kernel),
         Language     => Python_Name);
      Register_Command
        (Get_Scripts (Kernel),
         Command      => "__hash__",
         Handler      => Python_Location_Command_Handler'Access,
         Class        => Get_File_Location_Class (Kernel),
         Language     => Python_Name);
      Register_Command
        (Get_Scripts (Kernel),
         Command      => "__cmp__",
         Minimum_Args => 1,
         Maximum_Args => 1,
         Handler      => Python_Location_Command_Handler'Access,
         Class        => Get_File_Location_Class (Kernel),
         Language     => Python_Name);
   end Register_Module;

   --------------
   -- Load_Dir --
   --------------

   procedure Load_Dir
     (Kernel             : access GPS.Kernel.Kernel_Handle_Record'Class;
      Dir                : Virtual_File;
      Default_Autoload   : Boolean;
      Ignore_User_Config : Boolean)
   is
      function To_Load (File : Virtual_File) return Boolean;
      --  Whether File should be loaded

      -------------
      -- To_Load --
      -------------

      function To_Load (File : Virtual_File) return Boolean is
      begin
         return (Ignore_User_Config and then Default_Autoload)
           or else
             (not Ignore_User_Config and then Load_File_At_Startup
             (Kernel, File, Default => Default_Autoload));
      end To_Load;

      Script : constant Scripting_Language :=
                 Lookup_Scripting_Language
                   (Get_Scripts (Kernel), Python_Name);

   begin
      if Script /= null then
         --  Make sure the error messages will not be lost

         Set_Default_Console (Script, Kernel.Get_Messages_Window);

         --  This adds to sys.path
         Load_Directory (Script, Dir, To_Load'Unrestricted_Access);
      end if;
   end Load_Dir;

   --------------------------------------
   -- Load_System_Python_Startup_Files --
   --------------------------------------

   procedure Load_System_Python_Startup_Files
     (Kernel : access GPS.Kernel.Kernel_Handle_Record'Class)
   is
      Env_Path : constant File_Array := Get_Custom_Path;
   begin
      Load_Dir (Kernel, Support_Core_Dir (Kernel), Default_Autoload => True,
                Ignore_User_Config => True);
      Load_Dir (Kernel, Support_UI_Dir (Kernel), Default_Autoload => True,
                Ignore_User_Config => True);
      Load_Dir (Kernel, Support_No_Autoload_Dir (Kernel),
                Default_Autoload => False, Ignore_User_Config => True);
      Load_Dir
        (Kernel, Autoload_System_Dir (Kernel), Default_Autoload => True,
         Ignore_User_Config => False);
      Load_Dir
        (Kernel, No_Autoload_System_Dir (Kernel), Default_Autoload => False,
         Ignore_User_Config => False);

      for J in Env_Path'Range loop
         if Env_Path (J).Is_Directory then
            Load_Dir (Kernel, Env_Path (J), Default_Autoload => True,
                      Ignore_User_Config => False);
         end if;
      end loop;
   end Load_System_Python_Startup_Files;

   ------------------------------------
   -- Load_User_Python_Startup_Files --
   ------------------------------------

   procedure Load_User_Python_Startup_Files
     (Kernel : access GPS.Kernel.Kernel_Handle_Record'Class) is
   begin
      Load_Dir (Kernel, Autoload_User_Dir (Kernel), Default_Autoload => True,
                Ignore_User_Config => False);
   end Load_User_Python_Startup_Files;

   ---------------------------------
   -- Python_File_Command_Handler --
   ---------------------------------

   procedure Python_File_Command_Handler
     (Data : in out Callback_Data'Class; Command : String)
   is
      Kernel   : constant Kernel_Handle  := Get_Kernel (Data);
      Instance : constant Class_Instance :=
                   Nth_Arg (Data, 1, Get_File_Class (Kernel));
      Info     : constant Virtual_File := Get_Data (Instance);
      function Convert is new Ada.Unchecked_Conversion
        (Ada.Containers.Hash_Type, Integer);
   begin
      if Command = "__str__" or else Command = "__repr__" then
         Set_Return_Value (Data, Full_Name (Info));

      elsif Command = "__cmp__" then
         begin
            declare
               File : constant Virtual_File :=
                        Nth_Arg (Data, 2);
            begin
               if Info < File then
                  Set_Return_Value (Data, -1);
               elsif Info = File then
                  Set_Return_Value (Data, 0);
               else
                  Set_Return_Value (Data, 1);
               end if;
            end;
         exception
            when Invalid_Parameter | No_Such_Parameter =>
               Set_Return_Value (Data, 1);
         end;

      elsif Command = "__hash__" then
         Set_Return_Value (Data, Convert (Full_Name_Hash (Info)));
      end if;

   exception
      when Invalid_Parameter =>
         if Command = "__cmp__" then
            --  We are comparing a File with something else
            Set_Return_Value (Data, -1);
         else
            raise;
         end if;
   end Python_File_Command_Handler;

   ------------------
   -- Save_Desktop --
   ------------------

   overriding function Save_Desktop
     (Self : not null access Python_MDI_Child_Record)
      return XML_Utils.Node_Ptr
   is
      N : Node_Ptr;
   begin
      if Self.Save_Desktop /= null then
         declare
            Args : Callback_Data'Class :=
              Create (Get_Script (Self.Save_Desktop.all), 1);
         begin
            Set_Nth_Arg
              (Args, 1, Create_MDI_Window_Instance
                 (Get_Script (Self.Save_Desktop.all), Self.Kernel, Self));

            declare
               R : constant List_Instance'Class :=
                 Execute (Self.Save_Desktop, Args);
               Name : constant String := Nth_Arg (R, 1);
               Data : constant String := Nth_Arg (R, 2);
            begin
               N := new Node;
               N.Tag := new String'(Name);

               if Data = "" then
                  N.Value := new String'(Data);
               end if;
            end;

            Free (Args);
         end;
      end if;
      return N;
   end Save_Desktop;

   --------------------------------
   -- Python_GUI_Command_Handler --
   --------------------------------

   procedure Python_GUI_Command_Handler
     (Data : in out Callback_Data'Class; Command : String)
   is
      Widget : Glib.Object.GObject;
      Child  : Python_MDI_Child;
      Group  : Child_Group;
      Position : Child_Position;
   begin
      if Command = "add" then
         Widget := From_PyGtk (Data, 1);
         if Widget /= null then
            Group := Child_Group (Nth_Arg (Data, 4, Integer (Group_Default)));
            Position := Child_Position'Val
              (Nth_Arg (Data, 5, Child_Position'Pos (Position_Automatic)));

            Child := new Python_MDI_Child_Record;
            Initialize (Child, Gtk_Widget (Widget), Group => Group,
                        Module => Python_Views.Get_Module,
                        Desktop_Independent => False);
            Child.Save_Desktop := Nth_Arg (Data, 6, Default => null);

            Set_Title (Child, Nth_Arg (Data, 2, ""), Nth_Arg (Data, 3, ""));
            Put (Get_MDI (Get_Kernel (Data)), Child, Position);
            Set_Focus_Child (Child);
         end if;
      end if;
   end Python_GUI_Command_Handler;

   ------------------------------------
   -- Python_Project_Command_Handler --
   ------------------------------------

   procedure Python_Project_Command_Handler
     (Data : in out Callback_Data'Class; Command : String)
   is
      use type Ada.Containers.Hash_Type;
      Project : constant Project_Type := Get_Data (Data, 1);
   begin
      if Command = "__str__" then
         Set_Return_Value (Data, Project.Name);

      elsif Command = "__repr__" then
         Set_Return_Value (Data, Full_Name (Project_Path (Project)));

      elsif Command = "__cmp__" then
         declare
            Project2 : constant Project_Type := Get_Data (Data, 2);
            Name  : constant Virtual_File := Project_Path (Project);
            Name2 : constant Virtual_File := Project_Path (Project2);
         begin
            if Name < Name2 then
               Set_Return_Value (Data, -1);
            elsif Name = Name2 then
               Set_Return_Value (Data, 0);
            else
               Set_Return_Value (Data, 1);
            end if;
         end;

      elsif Command = "__hash__" then
         Set_Return_Value
           (Data,
            Integer
              (Full_Name_Hash (Project_Path (Project))
               mod Ada.Containers.Hash_Type (Integer'Last)));
      end if;

   exception
      when Invalid_Parameter =>
         if Command = "__cmp__" then
            --  We are comparing a Project with something else
            Set_Return_Value (Data, -1);
         else
            raise;
         end if;
   end Python_Project_Command_Handler;

   -----------------------------------
   -- Python_Entity_Command_Handler --
   -----------------------------------

   procedure Python_Entity_Command_Handler
     (Data : in out Callback_Data'Class; Command : String)
   is
      Kernel  : constant Kernel_Handle := Get_Kernel (Data);
      Entity  : constant General_Entity := Get_Data (Data, 1);
      Entity2 : General_Entity;
      Decl    : General_Entity_Declaration;
   begin
      if Command = "__str__"
        or else Command = "__repr__"
      then
         if Kernel.Databases.Is_Predefined_Entity (Entity) then
            Set_Return_Value (Data, Kernel.Databases.Get_Name (Entity));
         else
            Decl := Kernel.Databases.Get_Declaration (Entity);

            Set_Return_Value
              (Data,
               Kernel.Databases.Get_Name (Entity) & ':'
               & (+Decl.Loc.File.Base_Name) & ':'
               & Image (Decl.Loc.Line) & ':'
               & Image (Integer (Decl.Loc.Column)));
         end if;

      elsif Command = "__hash__" then
         Set_Return_Value (Data, Kernel.Databases.Hash (Entity));

      elsif Command = "__cmp__" then
         Entity2 := Get_Data (Data, 2);
         Set_Return_Value (Data, Kernel.Databases.Cmp (Entity, Entity2));
      end if;

   exception
      when Invalid_Parameter =>
         if Command = "__cmp__" then
            --  We are comparing an Entity with something else
            Set_Return_Value (Data, -1);
         else
            raise;
         end if;
   end Python_Entity_Command_Handler;

   -------------------------------------
   -- Python_Location_Command_Handler --
   -------------------------------------

   procedure Python_Location_Command_Handler
     (Data : in out Callback_Data'Class; Command : String)
   is
      Info     : constant File_Location_Info := Get_Data (Data, 1);
      Fileinfo : constant Virtual_File := Get_Data (Get_File (Info));
   begin
      if Command = "__str__"
        or else Command = "__repr__"
      then
         Set_Return_Value
           (Data,
            +Base_Name (Fileinfo) & ':'
            & Image (Get_Line (Info)) & ':'
            & Image (Integer (Get_Column (Info))));

      elsif Command = "__hash__" then
         Set_Return_Value
           (Data, Integer
            (Hash (+Full_Name (Fileinfo)
                   & Image (Get_Line (Info))
                   & Image (Integer (Get_Column (Info))))));

      elsif Command = "__cmp__" then
         declare
            use Basic_Types;

            Info2     : constant File_Location_Info := Get_Data (Data, 2);
            Fileinfo2 : constant Virtual_File := Get_Data (Get_File (Info2));
            Line1, Line2 : Integer;
            Col1, Col2   : Visible_Column_Type;
         begin
            if Fileinfo < Fileinfo2 then
               Set_Return_Value (Data, -1);
            elsif Fileinfo = Fileinfo2 then
               Line1 := Get_Line (Info);
               Line2 := Get_Line (Info2);

               if Line1 < Line2 then
                  Set_Return_Value (Data, -1);

               elsif Line1 = Line2 then
                  Col1 := Get_Column (Info);
                  Col2 := Get_Column (Info2);

                  if Col1 < Col2 then
                     Set_Return_Value (Data, -1);
                  elsif Col1 = Col2 then
                     Set_Return_Value (Data, 0);
                  else
                     Set_Return_Value (Data, 1);
                  end if;

               else
                  Set_Return_Value (Data, 1);
               end if;
            else
               Set_Return_Value (Data, 1);
            end if;
         end;
      end if;

   exception
      when Invalid_Parameter =>
         if Command = "__cmp__" then
            --  We are comparing a File_Location with something else
            Set_Return_Value (Data, -1);
         else
            raise;
         end if;
   end Python_Location_Command_Handler;

   -------------
   -- Destroy --
   -------------

   overriding procedure Destroy (Module : in out Python_Module_Record) is
   begin
      Unregister_Python_Scripting (Get_Scripts (Get_Kernel (Module)));
   end Destroy;

end Python_Module;
