-----------------------------------------------------------------------
--                 Odd - The Other Display Debugger                  --
--                                                                   --
--                         Copyright (C) 2000                        --
--                 Emmanuel Briot and Arnaud Charlet                 --
--                                                                   --
-- Odd is free  software;  you can redistribute it and/or modify  it --
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

with Gtk.Arguments;
with Gtk.Widget; use Gtk.Widget;

package Main_Debug_Window_Pkg.Callbacks is
   function On_Main_Debug_Window_Delete_Event
     (Object : access Gtk_Widget_Record'Class;
      Params : Gtk.Arguments.Gtk_Args) return Boolean;

   procedure On_Open_Program1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Open_Core_Dump1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Open_Session1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Save_Session_As1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Attach_To_Process1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Detach_Process1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Print_Graph1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Change_Directory1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Close1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Restart1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Exit1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Undo3_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Redo1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Cut1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Copy1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Paste1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Clear1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Delete1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Select_All1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Edit_Source1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Reload_Source1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Preferences1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Gdb_Settings1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Lookup_1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Find_1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Find_2_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Find_Words_Only1_Activate
     (Object : access Gtk_Check_Menu_Item_Record'Class);

   procedure On_Find_Case_Sensitive1_Activate
     (Object : access Gtk_Check_Menu_Item_Record'Class);

   procedure On_Execution_Window1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Gdb_Console1_Activate
     (Object : access Gtk_Check_Menu_Item_Record'Class);

   procedure On_Source_Window1_Activate
     (Object : access Gtk_Check_Menu_Item_Record'Class);

   procedure On_Data_Window1_Activate
     (Object : access Gtk_Check_Menu_Item_Record'Class);

   procedure On_Machine_Code_Window1_Activate
     (Object : access Gtk_Check_Menu_Item_Record'Class);

   procedure On_Run1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Run_Again1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Start1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Run_In_Execution_Window1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Step1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Step_Instruction1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Next1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Next_Instruction1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Until1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Finish1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Continue1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Continue_Without_Signal1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Kill1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Interrupt1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Abort1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Command_History1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Previous1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Next2_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Find_Backward1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Find_Forward1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Quit_Search1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Complete1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Apply1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Clear_Line1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Clear_Window1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Define_Command1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Edit_Buttons1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Backtrace1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Threads1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Processes1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Signals1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Edit_Breakpoints1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Edit_Displays1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Edit_Watchpoints1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Examine_Memory1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Print1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Display1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Display_Local_Variables1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Display_Arguments1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Display_Registers1_Activate
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Display_Machine_Code1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_More_Status_Display1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Rotate_Graph1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Layout_Graph1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Refresh1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Overview1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_On_Item1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_On_Window1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_What_Now_1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Tip_Of_The_Day1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Odd_Reference1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Odd_News1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Gdb_Reference1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Odd_License1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Odd_Www_Page1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_About_Odd1_Activate
     (Object : access Gtk_Menu_Item_Record'Class);

   procedure On_Print1_Clicked
     (Object : access Gtk_Widget_Record'Class;
      Params : Gtk.Arguments.Gtk_Args);

   procedure On_Display1_Clicked
     (Object : access Gtk_Widget_Record'Class;
      Params : Gtk.Arguments.Gtk_Args);

   procedure On_Up1_Activate
     (Object : access Gtk_Widget_Record'Class;
      Params : Gtk.Arguments.Gtk_Args);

   procedure On_Down1_Activate
     (Object : access Gtk_Widget_Record'Class;
      Params : Gtk.Arguments.Gtk_Args);

end Main_Debug_Window_Pkg.Callbacks;
