with Glide_Kernel; use Glide_Kernel;
with Gtk.Window; use Gtk.Window;

package body Glide_Main_Window is

   -------------
   -- Gtk_New --
   -------------

   procedure Gtk_New
     (Main_Window : out Glide_Window;
      Key         : String;
      Menu_Items  : Gtk_Item_Factory_Entry_Array) is
   begin
      Main_Window := new Glide_Window_Record;
      Glide_Main_Window.Initialize (Main_Window, Key, Menu_Items);
   end Gtk_New;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (Main_Window : access Glide_Window_Record'Class;
      Key         : String;
      Menu_Items  : Gtk_Item_Factory_Entry_Array) is
   begin
      GVD.Main_Window.Initialize (Main_Window, Key, Menu_Items);
      Gtk_New (Main_Window.Kernel, Gtk_Window (Main_Window));
   end Initialize;

end Glide_Main_Window;
