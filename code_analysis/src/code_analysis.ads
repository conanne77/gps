-----------------------------------------------------------------------
--                               G P S                               --
--                                                                   --
--                  Copyright (C) 2006-2007, AdaCore                 --
--                                                                   --
-- GPS is Free  software;  you can redistribute it and/or modify  it --
-- under the terms of the GNU General Public License as published by --
-- the Free Software Foundation; either version 2 of the License, or --
-- (at your option) any later version.                               --
--                                                                   --
-- This program is  distributed in the hope that it will be  useful, --
-- but  WITHOUT ANY WARRANTY;  without even the  implied warranty of --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU --
-- General Public License for more details. You should have received --
-- a copy of the GNU General Public License along with this program; --
-- if not,  write to the  Free Software Foundation, Inc.,  59 Temple --
-- Place - Suite 330, Boston, MA 02111-1307, USA.                    --
-----------------------------------------------------------------------

--  <description>
--  This package provides a low level structure designed to store code
--  analysis information such as code coverage (provided by gcov), metrics,
--  stack usage, memory usage, (Valgrind).
--  Information are stored in a tree structure with the following
--  levels: Project, File, Subprogram, Line.
--  </description>

with Ada.Containers.Indefinite_Hashed_Maps; use Ada.Containers;
with Ada.Containers.Hashed_Maps;
with Ada.Strings.Hash;
with Ada.Strings.Equal_Case_Insensitive;
with Ada.Unchecked_Deallocation;
with GNAT.Strings;                          use GNAT.Strings;

with Projects;                              use Projects;
with VFS;                                   use VFS;

package Code_Analysis is

   -----------------------------
   -- Tree decoration records --
   -----------------------------

   type Coverage_Status is
     (Valid,
      File_Not_Found,
      --  Error status obtained if no Gcov file was found associated to a
      --  source file when trying to load Gcov info
      File_Corrupted
      --  Error status obtained when the Gcov file that is attempted to be
      --  parsed is older than the source file associated to
     );

   type Coverage is tagged record
      Coverage : Integer;
      Status   : Coverage_Status := Valid;
   end record;
   --  Basic code coverage information
   --  Record the Line's execution counts and the Subprogram, File and Project
   --  number of not covered lines
   --  When negative, it stands for a Gcov_Error_Code (see Code_Coverage.ads)

   type Node_Coverage is new Coverage with record
      Children : Natural;
   end record;
   --  Extra node coverage information
   --  Children is the Subprogram, File or Project children count

   type Subprogram_Coverage is new Node_Coverage with record
      Called : Natural;
   end record;
   --  Specific Subprogram extra info
   --  The number of time the subprogram has been called

   type Project_Coverage is new Node_Coverage with record
      Have_Runs : Boolean := False;
      Runs      : Natural;
   end record;
   --  Store project number of call if this info is available
   --  Older gcov than gcov (GCC) 4.1.3 20070620 were fitted with a runs field
   --  in their header, reporting the number of executions of the produced
   --  executable file

   type Coverage_Access is access all Coverage'Class;

   type Analysis is record
      Coverage_Data : Coverage_Access;
      --  Future other specific analysis records might be added here, such as
      --  Metrics_Data : Metrics_Record_Access;
      --  SSAT_Data    : SSAT_Record_Access;
   end record;
   --  Store the various code analysis information
   --  ??? In the future, we want a more flexible data structure where each
   --  module can store their data without having visibility on all these
   --  modules in code_analysis.
   --  At this stage, we don't want to elaborate something more complicated.
   --  Furthermore we will need to have visibility on all structures within a
   --  same module when writing advanced tools which will cross information
   --  coming from different code analysis tools.

   ----------------
   -- Tree types --
   ----------------

   type Node;
   type Line;
   type Subprogram;
   type File;
   type Project;

   type Subprogram_Access is access all Subprogram;
   type File_Access       is access all File;
   type Project_Access    is access all Project;
   type Node_Access       is access all Node'Class;

   package Subprogram_Maps is
     new Indefinite_Hashed_Maps
       (Key_Type        => String,
        Element_Type    => Subprogram_Access,
        Hash            => Ada.Strings.Hash,
        Equivalent_Keys => Ada.Strings.Equal_Case_Insensitive);
   --  Used to stored the Subprogram nodes of every Files

   package File_Maps is
     new Hashed_Maps
       (Key_Type        => VFS.Virtual_File,
        Element_Type    => File_Access,
        Hash            => VFS.Full_Name_Hash,
        Equivalent_Keys => VFS."=");
   --  Used to stored the File nodes of every Projects

   package Project_Maps is
     new Hashed_Maps
       (Key_Type        => Project_Type,
        Element_Type    => Project_Access,
        Hash            => Project_Name_Hash,
        Equivalent_Keys => Projects."=");
   --  Used to stored the Project nodes

   type Code_Analysis_Tree is access all Project_Maps.Map;

   type Node is tagged record
      Analysis_Data : Analysis;
   end record;
   --  Abstract father type of all the following specific node types
   --  Line, Subprogram, File, Project

   type Line is new Node with record
      Number   : Natural;
      Contents : String_Access;
   end record;

   Null_Line : constant Line := (Node with Number => 0, Contents => null);

   type Line_Array is array (Positive range <>) of Line;

   type Line_Array_Access is access Line_Array;

   type Subprogram is new Node with record
      Name   : String_Access;
      Line   : Natural := 1;
      Column : Natural := 1;
      Start  : Natural := 0;
      Stop   : Natural := 0;
   end record;
   --  A Subprogram is identified in the Subprograms' maps of every File record
   --  by a string type
   --  Line is the declaration line within the encapsulating file
   --  Column is the declaration column within the encapsulation file
   --  Start is the starting line of the definition of the subprogram
   --  Stop is the ending line of the definition of the subprogram

   type File is new Node with record
      Name        : VFS.Virtual_File;
      Subprograms : Subprogram_Maps.Map;
      Lines       : Line_Array_Access;
   end record;

   type Project is new Node with record
      Name  : Project_Type;
      Files : File_Maps.Map;
   end record;

   Pix_Col  : constant := 0;
   --  Gtk_Tree_Model column number dedicated to the icons associated with each
   --  node of code_analysis data structure
   Name_Col : constant := 1;
   --  Gtk_Tree_Model column number dedicated to the name of the nodes of
   --  code_analysis structure
   Node_Col : constant := 2;
   --  Gtk_Tree_Model column number dedicated to the nodes of code_analysis
   --  structure
   File_Col : constant := 3;
   --  Gtk_Tree_Model column number dedicated to the node corresponding file
   --  of the code_analysis structure (usefull for flat views)
   --  It is filled with :
   --   - nothing if the node is a project
   --   - the file_node itself if its a file
   --   - the parent file_node if its a subprogram
   Prj_Col  : constant := 4;
   --  Gtk_Tree_Model column number dedicated to the node corresponding project
   --  of the code_analysis structure in every circumstance
   --  (usefull for flat views)
   Cov_Col  : constant := 5;
   --  Gtk_Tree_Model column number dedicated to the coverage information
   --  contained in the node coverage records
   Cov_Sort : constant := 6;
   --  Gtk_Tree_Model column number dedicated to some raw coverage information
   --  used to sort rows by not covered lines amount order
   Cov_Bar_Txt : constant := 7;
   --  Ctk_Tree_Model column number dedicated to the coverage percentage column
   Cov_Bar_Val : constant := 8;
   --  Gtk_Tree_Model column number dedicated to the raw coverage percentage
   --  values, in order to be use in sorting operations

   -------------------
   -- Get_Or_Create --
   -------------------

   function Get_Or_Create
     (File_Node : File_Access;
      Sub_Name  : String_Access) return Subprogram_Access;

   function Get_Or_Create
     (Project_Node : Project_Access;
      File_Name    : VFS.Virtual_File) return File_Access;

   function Get_Or_Create
     (Projects     : Code_Analysis_Tree;
      Project_Name : Project_Type) return Project_Access;
   --  allow to get an access pointing on an identified tree node
   --  if the node doesn't exists, it is created

   ------------------------------------
   -- Determinist Ordered Provisions --
   ------------------------------------

   type Subprogram_Array is array (Positive range <>) of Subprogram_Access;
   --  Used to sort Subprogram nodes in a determinist way before to process a
   --  whole hashed map, that can't be iterate in a determinist order

   type File_Array is array (Positive range <>) of File_Access;
   --  Used to sort File nodes in a determinist way before to process a
   --  whole hashed map, that can't be iterate in a determinist order

   type Project_Array is array (Positive range <>) of Project_Access;
   --  Used to sort Project nodes in a determinist way before to process a
   --  whole hashed map, that can't be iterate in a determinist order

   procedure Sort_Subprograms (Nodes : in out Subprogram_Array);
   --  Heap sorts the given Subprogram_Array in alphabetical order based on the
   --  Subprogram.Name

   procedure Sort_Files (Nodes : in out File_Array);
   --  Heap sorts the given File_Array in alphabetical order based on the
   --  VFS.Base_Name (File.Name)

   procedure Sort_Projects (Nodes : in out Project_Array);
   --  Heap sorts the given Project_Array in alphabetical order based on the
   --  String'(Project_Name (Project.Name))

   -------------
   -- Free-er --
   -------------

   procedure Free_Code_Analysis (Projects : Code_Analysis_Tree);
   --  Free a whole code analysis structure

   procedure Unchecked_Free is new
     Ada.Unchecked_Deallocation (Coverage'Class, Coverage_Access);

   -------------
   -- Free-er --
   -------------

   procedure Free_Line (Line_Node : in out Line'Class);
   --  Free the data associated to a Line

   procedure Free_Subprogram (Sub_Node : in out Subprogram_Access);
   --  Free every children and himself

   procedure Free_File (File_Node : in out File_Access);
   --  Free every children and himself

   procedure Free_Project (Project_Node : in out Project_Access);
   --  Free every children and himself

   procedure Free_Analysis (Analysis_Id : in out Analysis);
   --  Free an Analysis record, so also a
   --  Coverage record if allocated
   --  and futur other specific analysis records should be added here

private

   procedure Unchecked_Free is new
     Ada.Unchecked_Deallocation (String, String_Access);

   procedure Unchecked_Free is new
     Ada.Unchecked_Deallocation (Subprogram, Subprogram_Access);

   procedure Unchecked_Free is new
     Ada.Unchecked_Deallocation (File, File_Access);

   procedure Unchecked_Free is new
     Ada.Unchecked_Deallocation (Line_Array, Line_Array_Access);

   procedure Unchecked_Free is new
     Ada.Unchecked_Deallocation (Project, Project_Access);

end Code_Analysis;
