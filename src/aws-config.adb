------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                            Copyright (C) 2000                            --
--                      Dmitriy Anisimkov & Pascal Obry                     --
--                                                                          --
--  This library is free software; you can redistribute it and/or modify    --
--  it under the terms of the GNU General Public License as published by    --
--  the Free Software Foundation; either version 2 of the License, or (at   --
--  your option) any later version.                                         --
--                                                                          --
--  This library is distributed in the hope that it will be useful, but     --
--  WITHOUT ANY WARRANTY; without even the implied warranty of              --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU       --
--  General Public License for more details.                                --
--                                                                          --
--  You should have received a copy of the GNU General Public License       --
--  along with this library; if not, write to the Free Software Foundation, --
--  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.          --
--                                                                          --
--  As a special exception, if other files instantiate generics from this   --
--  unit, or you link this unit with other files to produce an executable,  --
--  this  unit  does not  by itself cause  the resulting executable to be   --
--  covered by the GNU General Public License. This exception does not      --
--  however invalidate any other reasons why the executable file  might be  --
--  covered by the  GNU Public License.                                     --
------------------------------------------------------------------------------

--  $Id$

with Ada.Strings.Unbounded;
with Ada.Text_IO;

with GNAT.Regpat;

with AWS.Utils;

package body AWS.Config is

   use Ada.Strings.Unbounded;

   Admin_URI_Value          : Unbounded_String := To_Unbounded_String ("");
   Server_Name_Value        : Unbounded_String := To_Unbounded_String ("");
   Log_File_Directory_Value : Unbounded_String := To_Unbounded_String ("./");
   Max_Connection_Value     : Positive := 3;
   Server_Port_Value        : Positive := 8080;

   procedure Initialize;
   --  read aws.ini file if present and initialize this package accordingly.

   ---------------
   -- Admin_URI --
   ---------------

   function Admin_URI return String is
   begin
      return To_String (Admin_URI_Value);
   end Admin_URI;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is

      use GNAT;
      use Ada;
      use type GNAT.Regpat.Match_Location;

      procedure Error_Message (Message : in String);
      --  Output error message with filename and line number.

      Regexp  : constant String := "^ *([#a-zA-z]+) +([0-9a-zA-z/\-:.]+)";
      Matcher : constant Regpat.Pattern_Matcher := Regpat.Compile (Regexp);
      Matches : Regpat.Match_Array (1 .. 2);

      File    : Text_IO.File_Type;
      Buffer  : String (1 .. 1024);
      Last    : Natural;
      Line    : Natural := 0;
      --  current line number parsed

      -------------------
      -- Error_Message --
      -------------------

      procedure Error_Message (Message : in String) is
      begin
         Text_IO.Put ("(aws.ini:");
         Text_IO.Put (AWS.Utils.Image (Line));
         Text_IO.Put_Line (") " & Message);
      end Error_Message;

   begin
      Text_IO.Open (Name => "aws.ini", File => File, Mode => Text_IO.In_File);

      while not Text_IO.End_Of_File (File) loop
         Text_IO.Get_Line (File, Buffer, Last);
         Line := Line + 1;

         if Last /= 0 then
            Regpat.Match (Matcher, Buffer (1 .. Last), Matches);

            if Matches (2) /= Regpat.No_Match then
               declare
                  Key   : constant String
                    := Buffer (Matches (1).First .. Matches (1).Last);
                  Value : constant String
                    := Buffer (Matches (2).First .. Matches (2).Last);
               begin
                  if Key /= "#" then

                     if Key = "Server_Name" then
                        Server_Name_Value := To_Unbounded_String (Value);

                     elsif Key = "Admin_URI" then
                        Admin_URI_Value := To_Unbounded_String (Value);

                     elsif Key = "Log_File_Directory" then
                        if Value (Value'Last) = '/' then
                           Log_File_Directory_Value
                             := To_Unbounded_String (Value);
                        else
                           Log_File_Directory_Value
                             := To_Unbounded_String (Value & '/');
                        end if;

                     elsif Key = "Max_Connection" then
                        begin
                           Max_Connection_Value := Positive'Value (Value);
                        exception
                           when others =>
                              Error_Message ("wrong value for " & Key);
                        end;

                     elsif Key = "Server_Port" then
                        begin
                           Server_Port_Value := Positive'Value (Value);
                        exception
                           when others =>
                              Error_Message ("wrong value for " & Key);
                        end;

                     else
                        Error_Message ("unrecognized option " & Key);
                     end if;
                  end if;
               end;
            else
               Error_Message ("wrong format");
            end if;
         end if;
      end loop;

      Text_IO.Close (File);
   exception
      when Text_IO.Name_Error =>
         null;
   end Initialize;

   ------------------------
   -- Log_File_Directory --
   ------------------------

   function Log_File_Directory return String is
   begin
      return To_String (Log_File_Directory_Value);
   end Log_File_Directory;

   --------------------
   -- Max_Connection --
   --------------------

   function Max_Connection return Positive is
   begin
      return Max_Connection_Value;
   end Max_Connection;

   -----------------
   -- Server_Name --
   -----------------

   function Server_Name return String is
   begin
      return To_String (Server_Name_Value);
   end Server_Name;

   -----------------
   -- Server_Port --
   -----------------

   function Server_Port return Positive is
   begin
      return Server_Port_Value;
   end Server_Port;

begin
   Initialize;
end AWS.Config;
