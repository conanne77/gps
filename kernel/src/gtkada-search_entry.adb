------------------------------------------------------------------------------
--                  GtkAda - Ada95 binding for Gtk+/Gnome                   --
--                                                                          --
--                     Copyright (C) 2013-2013, AdaCore                     --
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

with Gdk.Event;          use Gdk.Event;
with Gtk.Style_Context;  use Gtk.Style_Context;
with Gtk.Widget;         use Gtk.Widget;
with Gtkada.Handlers;    use Gtkada.Handlers;
with GPS.Intl;           use GPS.Intl;
with GPS.Stock_Icons;    use GPS.Stock_Icons;

package body Gtkada.Search_Entry is

   procedure On_Clear_Entry
      (Self  : access Gtk_Entry_Record'Class;
       Pos   : Gtk_Entry_Icon_Position;
       Event : Gdk_Event_Button);
   --  Called when the user presses the "clear" icon

   procedure On_Changed (Self : access Gtk_Widget_Record'Class);
   --  Called when the text of the entry has changed.

   --------------------
   -- On_Clear_Entry --
   --------------------

   procedure On_Clear_Entry
      (Self  : access Gtk_Entry_Record'Class;
       Pos   : Gtk_Entry_Icon_Position;
       Event : Gdk_Event_Button)
   is
      pragma Unreferenced (Pos, Event);
   begin
      Self.Set_Text ("");
   end On_Clear_Entry;

   ----------------
   -- On_Changed --
   ----------------

   procedure On_Changed (Self : access Gtk_Widget_Record'Class) is
      S  : constant Gtkada_Search_Entry := Gtkada_Search_Entry (Self);
   begin
      if S.Get_Text /= "" then
         S.Set_Icon_From_Stock (Gtk_Entry_Icon_Secondary, GPS_Clear_Entry);
         S.Set_Icon_Activatable (Gtk_Entry_Icon_Secondary, True);
         S.Set_Icon_Tooltip_Text
            (Gtk_Entry_Icon_Secondary, -"Clear the pattern");
      else
         S.Set_Icon_From_Stock (Gtk_Entry_Icon_Secondary, "");
         S.Set_Icon_Activatable (Gtk_Entry_Icon_Secondary, False);
      end if;
   end On_Changed;

   -------------
   -- Gtk_New --
   -------------

   procedure Gtk_New
      (Self        : out Gtkada_Search_Entry;
       Placeholder : String := "") is
   begin
      Self := new Gtkada_Search_Entry_Record;
      Gtk.GEntry.Initialize (Self);

      if Placeholder /= "" then
         Self.Set_Placeholder_Text (Placeholder);
      end if;

      Get_Style_Context (Self).Add_Class ("search");

      Self.On_Icon_Release (On_Clear_Entry'Access);
      Widget_Callback.Connect (Self, Signal_Changed, On_Changed'Access);
   end Gtk_New;

end Gtkada.Search_Entry;