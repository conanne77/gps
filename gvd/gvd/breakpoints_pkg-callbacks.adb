-----------------------------------------------------------------------
--                   GVD - The GNU Visual Debugger                   --
--                                                                   --
--                      Copyright (C) 2000-2002                      --
--                              ACT-Europe                           --
--                                                                   --
-- GVD is free  software;  you can redistribute it and/or modify  it --
-- under the terms of the GNU General Public License as published by --
-- the Free Software Foundation; either version 2 of the License, or --
-- (at your option) any later version.                               --
--                                                                   --
-- This program is  distributed in the hope that it will be  useful, --
-- but  WITHOUT ANY WARRANTY;  without even the  implied warranty of --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU --
-- General Public License for more details. You should have received --
-- a copy of the GNU General Public License along with this library; --
-- if not,  write to the  Free Software Foundation, Inc.,  59 Temple --
-- Place - Suite 330, Boston, MA 02111-1307, USA.                    --
-----------------------------------------------------------------------

with Glib;               use Glib;
with Glib.Object;        use Glib.Object;
with GVD.Types;          use GVD.Types;
with Basic_Types;        use Basic_Types;
with Gtk.Arguments;      use Gtk.Arguments;
with Debugger;           use Debugger;
with Odd_Intl;           use Odd_Intl;
with Gtk.Enums;          use Gtk.Enums;
with Gtk.Combo;          use Gtk.Combo;
with GUI_Utils;          use GUI_Utils;
with GVD.Code_Editors;   use GVD.Code_Editors;
with GVD.Process;        use GVD.Process;
with Gdk.Event;          use Gdk.Event;
with Gdk.Types.Keysyms;  use Gdk.Types.Keysyms;
with Breakpoints_Editor; use Breakpoints_Editor;

with Advanced_Breakpoint_Pkg; use Advanced_Breakpoint_Pkg;
with Ada.Exceptions;          use Ada.Exceptions;
with Traces;                  use Traces;

package body Breakpoints_Pkg.Callbacks is

   Me : constant Debug_Handle := Create ("Breakpoints_Pkg.Callbacks");

   use Gtk.Arguments;

   ---------------------------------
   -- On_Breakpoints_Delete_Event --
   ---------------------------------

   function On_Breakpoints_Delete_Event
     (Object : access Gtk_Widget_Record'Class;
      Params : Gtk.Arguments.Gtk_Args) return Boolean
   is
      pragma Unreferenced (Params);
   begin
      Hide (Object);
      return True;

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
         return False;
   end On_Breakpoints_Delete_Event;

   ------------------------------------
   -- On_Breakpoints_Key_Press_Event --
   ------------------------------------

   function On_Breakpoints_Key_Press_Event
     (Object : access Gtk_Widget_Record'Class;
      Params : Gtk.Arguments.Gtk_Args) return Boolean
   is
      Event : constant Gdk_Event := To_Event (Params, 1);
      use type Gdk.Types.Gdk_Key_Type;
   begin
      if Get_Key_Val (Event) = GDK_Delete then
         On_Remove_Clicked (Object);
      end if;
      return False;

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
         return False;
   end On_Breakpoints_Key_Press_Event;

   -------------------------
   -- On_Breakpoints_Show --
   -------------------------

   procedure On_Breakpoints_Show
     (Object : access Gtk_Widget_Record'Class)
   is
      Editor    : constant Breakpoint_Editor_Access :=
        Breakpoint_Editor_Access (Object);

   begin
      if Editor.Advanced_Breakpoints_Location /= null then
         declare
            Debugger     : Debugger_Access;
            WTX_Version  : Natural;
         begin
            Debugger := Editor.Process.Debugger;
            Info_WTX (Debugger, WTX_Version);

            if WTX_Version /= 3 then
               Hide (Editor.Advanced_Breakpoints_Location.Scope_Box);
               Hide (Editor.Advanced_Breakpoints_Watchpoints.Scope_Box);
               Hide (Editor.Advanced_Breakpoints_Exceptions.Scope_Box);
            else
               Show (Editor.Advanced_Breakpoints_Location.Scope_Box);
               Show (Editor.Advanced_Breakpoints_Watchpoints.Scope_Box);
               Show (Editor.Advanced_Breakpoints_Exceptions.Scope_Box);
            end if;
         end;
      end if;

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_Breakpoints_Show;

   ----------------------------------
   -- On_Location_Selected_Toggled --
   ----------------------------------

   procedure On_Location_Selected_Toggled
     (Object : access Gtk_Widget_Record'Class)
   is
      Breakpoints : constant Breakpoints_Access :=
        Breakpoints_Access (Object);
   begin
      Set_Sensitive (Breakpoints.File_Combo, True);
      Set_Sensitive (Breakpoints.Line_Spin, True);
      Set_Sensitive (Breakpoints.Address_Combo, False);
      Set_Sensitive (Breakpoints.Subprogram_Combo, False);
      Set_Sensitive (Breakpoints.Regexp_Combo, False);

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_Location_Selected_Toggled;

   -----------------------------------
   -- On_Subprogam_Selected_Toggled --
   -----------------------------------

   procedure On_Subprogam_Selected_Toggled
     (Object : access Gtk_Widget_Record'Class)
   is
      Breakpoints : constant Breakpoints_Access :=
        Breakpoints_Access (Object);
   begin
      Set_Sensitive (Breakpoints.File_Combo, False);
      Set_Sensitive (Breakpoints.Line_Spin, False);
      Set_Sensitive (Breakpoints.Address_Combo, False);
      Set_Sensitive (Breakpoints.Subprogram_Combo, True);
      Set_Sensitive (Breakpoints.Regexp_Combo, False);

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_Subprogam_Selected_Toggled;

   ---------------------------------
   -- On_Address_Selected_Toggled --
   ---------------------------------

   procedure On_Address_Selected_Toggled
     (Object : access Gtk_Widget_Record'Class)
   is
      Breakpoints : constant Breakpoints_Access := Breakpoints_Access (Object);
   begin
      Set_Sensitive (Breakpoints.File_Combo, False);
      Set_Sensitive (Breakpoints.Line_Spin, False);
      Set_Sensitive (Breakpoints.Address_Combo, True);
      Set_Sensitive (Breakpoints.Subprogram_Combo, False);
      Set_Sensitive (Breakpoints.Regexp_Combo, False);

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_Address_Selected_Toggled;

   --------------------------------
   -- On_Regexp_Selected_Toggled --
   --------------------------------

   procedure On_Regexp_Selected_Toggled
     (Object : access Gtk_Widget_Record'Class)
   is
      Breakpoints : constant Breakpoints_Access := Breakpoints_Access (Object);
   begin
      Set_Sensitive (Breakpoints.File_Combo, False);
      Set_Sensitive (Breakpoints.Line_Spin, False);
      Set_Sensitive (Breakpoints.Address_Combo, False);
      Set_Sensitive (Breakpoints.Subprogram_Combo, False);
      Set_Sensitive (Breakpoints.Regexp_Combo, True);

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_Regexp_Selected_Toggled;

   -----------------------------
   -- On_Add_Location_Clicked --
   -----------------------------

   procedure On_Add_Location_Clicked
     (Object : access Gtk_Widget_Record'Class)
   is
      B : Breakpoint_Identifier;
      pragma Unreferenced (B);
   begin
      B := Set_Location_Breakpoint (Breakpoint_Editor_Access (Object));

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_Add_Location_Clicked;

   --------------------------------
   -- On_Update_Location_Clicked --
   --------------------------------

   procedure On_Update_Location_Clicked
     (Object : access Gtk_Widget_Record'Class)
   is
      Editor    : constant Breakpoint_Editor_Access :=
        Breakpoint_Editor_Access (Object);
      Selection : constant Integer := Get_Selection_Index (Editor);
      Num       : Breakpoint_Identifier;

      WTX_Version : Natural;

   begin
      --  Only update the breakpoint if its type matches the current page.
      if Selection /= -1
        and then Editor.Process.Breakpoints (Selection).Except = null
      then
         Num := Set_Location_Breakpoint (Editor, Selection);

         --  Update scope and action for the selected breakpoint
         Info_WTX (Editor.Process.Debugger, WTX_Version);

         if WTX_Version = 3 then
            declare
               Scope_Action : constant Advanced_Breakpoint_Access :=
                 Editor.Advanced_Breakpoints_Location;
               Scope_Value  : GVD.Types.Scope_Type;
               Action_Value : GVD.Types.Action_Type;
            begin
               if Get_Active (Scope_Action.Scope_Task) then
                  Scope_Value := Current_Task;
               elsif Get_Active (Scope_Action.Scope_Pd) then
                  Scope_Value := Tasks_In_PD;
               elsif Get_Active (Scope_Action.Scope_Any) then
                  Scope_Value := Any_Task;
               end if;

               if Get_Active (Scope_Action.Action_Task) then
                  Action_Value := Current_Task;
               elsif Get_Active (Scope_Action.Action_Pd) then
                  Action_Value := Tasks_In_PD;
               elsif Get_Active (Scope_Action.Action_All) then
                  Action_Value := All_Tasks;
               end if;

               Set_Scope_Action (Editor.Process.Debugger, Scope_Value,
                                 Action_Value, Num);
            end;
         end if;

         for B in Editor.Process.Breakpoints'Range loop
            if Editor.Process.Breakpoints (B).Num = Num then
               Select_Row (Editor.Breakpoint_List, Gint (B) - 1, -1);
               exit;
            end if;
         end loop;
      end if;

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_Update_Location_Clicked;

   ----------------------------------
   -- On_Advanced_Location_Clicked --
   ----------------------------------

   procedure On_Advanced_Location_Clicked
     (Object : access Gtk_Widget_Record'Class)
   is
      Editor : constant Breakpoint_Editor_Access :=
        Breakpoint_Editor_Access (Object);
   begin
      Toggle_Advanced_Dialog (Editor);

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_Advanced_Location_Clicked;

   -------------------------------
   -- On_Add_Watchpoint_Clicked --
   -------------------------------

   procedure On_Add_Watchpoint_Clicked
     (Object : access Gtk_Widget_Record'Class)
   is
      pragma Unreferenced (Object);
   begin
      null;

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_Add_Watchpoint_Clicked;

   ----------------------------------
   -- On_Update_Watchpoint_Clicked --
   ----------------------------------

   procedure On_Update_Watchpoint_Clicked
     (Object : access Gtk_Widget_Record'Class)
   is
      pragma Unreferenced (Object);
   begin
      null;

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_Update_Watchpoint_Clicked;

   ------------------------------------
   -- On_Advanced_Watchpoint_Clicked --
   ------------------------------------

   procedure On_Advanced_Watchpoint_Clicked
     (Object : access Gtk_Widget_Record'Class)
   is
      Editor : constant Breakpoint_Editor_Access :=
        Breakpoint_Editor_Access (Object);
   begin
      Toggle_Advanced_Dialog (Editor);

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_Advanced_Watchpoint_Clicked;

   ------------------------------------
   -- On_Load_Exception_List_Clicked --
   ------------------------------------

   procedure On_Load_Exception_List_Clicked
     (Object : access Gtk_Widget_Record'Class)
   is
      Editor : constant Breakpoint_Editor_Access :=
        Breakpoint_Editor_Access (Object);
   begin
      Set_Busy (Editor.Process, True);

      declare
         Exception_Arr : Exception_Array :=
           List_Exceptions (Editor.Process.Debugger);
      begin
         if Exception_Arr'Length > 0 then
            Set_Sensitive (Editor.Hbox4, True);
            Add_Unique_Combo_Entry
              (Editor.Exception_Name, -"All exceptions");
            Add_Unique_Combo_Entry
              (Editor.Exception_Name, -"All assertions");

            for J in Exception_Arr'Range loop
               Add_Unique_Combo_Entry
                 (Editor.Exception_Name, Exception_Arr (J).Name.all);
            end loop;
         else
            Set_Sensitive (Editor.Hbox4, False);
         end if;

         Free (Exception_Arr);
      end;

      Set_Busy (Editor.Process, False);

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_Load_Exception_List_Clicked;

   ------------------------------
   -- On_Add_Exception_Clicked --
   ------------------------------

   procedure On_Add_Exception_Clicked
     (Object : access Gtk_Widget_Record'Class)
   is
      B      : Breakpoint_Identifier;
      pragma Unreferenced (B);

      Editor : constant Breakpoint_Editor_Access :=
        Breakpoint_Editor_Access (Object);

   begin
      B := Set_Exception_Breakpoint (Editor);

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_Add_Exception_Clicked;

   ---------------------------------
   -- On_Update_Exception_Clicked --
   ---------------------------------

   procedure On_Update_Exception_Clicked
     (Object : access Gtk_Widget_Record'Class)
   is
      Editor    : constant Breakpoint_Editor_Access :=
        Breakpoint_Editor_Access (Object);
      Selection : constant Integer := Get_Selection_Index (Editor);
      Num : Breakpoint_Identifier;
   begin
      --  Only update the breakpoint if its type matches the current page.
      if Selection /= -1
        and then Editor.Process.Breakpoints (Selection).Except /= null
      then
         Num := Set_Exception_Breakpoint (Editor, Selection);

         for B in Editor.Process.Breakpoints'Range loop
            if Editor.Process.Breakpoints (B).Num = Num then
               Select_Row (Editor.Breakpoint_List, Gint (B), -1);
               exit;
            end if;
         end loop;
      end if;

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_Update_Exception_Clicked;

   -----------------------------------
   -- On_Advanced_Exception_Clicked --
   -----------------------------------

   procedure On_Advanced_Exception_Clicked
     (Object : access Gtk_Widget_Record'Class)
   is
      Editor : constant Breakpoint_Editor_Access :=
        Breakpoint_Editor_Access (Object);
   begin
      Toggle_Advanced_Dialog (Editor);

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_Advanced_Exception_Clicked;

   -----------------------
   -- On_Remove_Clicked --
   -----------------------

   procedure On_Remove_Clicked
     (Object : access Gtk_Widget_Record'Class)
   is
      use Gint_List;
      Editor    : constant Breakpoint_Editor_Access :=
        Breakpoint_Editor_Access (Object);
      Selection : Gint;
   begin
      if Get_Selection (Editor.Breakpoint_List) /= Null_List then
         Selection := Get_Data (Get_Selection (Editor.Breakpoint_List));
         Remove_Breakpoint
           (Editor.Process.Debugger,
            Breakpoint_Identifier'Value
              (Get_Text (Editor.Breakpoint_List, Selection, 0)),
            Mode => GVD.Types.Visible);
      end if;

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_Remove_Clicked;

   ---------------------
   -- On_View_Clicked --
   ---------------------

   procedure On_View_Clicked
     (Object : access Gtk_Widget_Record'Class)
   is
      Editor    : constant Breakpoint_Editor_Access :=
        Breakpoint_Editor_Access (Object);
      Selection : constant Integer := Get_Selection_Index (Editor);
   begin
      if Selection /= -1 then
         Load_File
           (Editor.Process.Editor_Text,
            Editor.Process.Breakpoints (Selection).File.all);
         Set_Line
           (Editor.Process.Editor_Text,
            Editor.Process.Breakpoints (Selection).Line,
            Process => GObject (Editor.Process));
      end if;

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_View_Clicked;

   ----------------------
   -- On_Ok_Bp_Clicked --
   ----------------------

   procedure On_Ok_Bp_Clicked
     (Object : access Gtk_Widget_Record'Class)
   is
      Editor       : constant Breakpoint_Editor_Access :=
        Breakpoint_Editor_Access (Object);
      Scope_Action : constant Advanced_Breakpoint_Access :=
        Editor.Advanced_Breakpoints_Location;
      Debugger     : Debugger_Access;
      WTX_Version  : Natural;

   begin
      Debugger := Editor.Process.Debugger;
      Info_WTX (Debugger, WTX_Version);

      --  If we are using AE and the user has activated the "Set as
      --  default" checkbox for the scope and action values, send the
      --  appropriate commands to the debugger

      if WTX_Version = 3
        and then Editor.Advanced_Breakpoints_Location /= null
        and then Get_Active (Scope_Action.Set_Default)
      then
         declare
            Scope_Value  : Scope_Type;
            Action_Value : Action_Type;
         begin
            if Get_Active (Scope_Action.Scope_Task) then
               Scope_Value := Current_Task;
            elsif Get_Active (Scope_Action.Scope_Pd) then
               Scope_Value := Tasks_In_PD;
            elsif Get_Active (Scope_Action.Scope_Any) then
               Scope_Value := Any_Task;
            end if;

            if Get_Active (Scope_Action.Action_Task) then
               Action_Value := Current_Task;
            elsif Get_Active (Scope_Action.Action_Pd) then
               Action_Value := Tasks_In_PD;
            elsif Get_Active (Scope_Action.Action_All) then
               Action_Value := All_Tasks;
            end if;

            Set_Scope_Action (Debugger, Scope_Value, Action_Value);
         end;
      end if;

      Hide (Object);

   exception
      when E : others =>
         Trace (Me, "Unexpected exception: " & Exception_Information (E));
   end On_Ok_Bp_Clicked;

end Breakpoints_Pkg.Callbacks;
