------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                         Copyright (C) 2000-2001                          --
--                               ACT-Europe                                 --
--                                                                          --
--  Authors: Dmitriy Anisimokv - Pascal Obry                                --
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

with Ada.Text_IO;
with Ada.Exceptions;

with AWS.Server;
with AWS.Client;
with AWS.Status;
with AWS.MIME;
with AWS.Response;
with AWS.Parameters;
with AWS.Messages;

procedure Tclientto is

   use Ada;
   use Ada.Text_IO;
   use AWS;

   function CB (Request : in Status.Data) return Response.Data;

   task Server is
      entry Started;
      entry Stopped;
   end Server;

   HTTP : AWS.Server.HTTP;

   --------
   -- CB --
   --------

   function CB (Request : in Status.Data) return Response.Data is
      URI    : constant String          := Status.URI (Request);
      P_List : constant Parameters.List := Status.Parameters (Request);
   begin
      if URI = "/3sec" then
         delay 3.0;
         return Response.Build (MIME.Text_HTML, "3sec ok");

      elsif URI = "/10sec" then
         delay 10.0;
         return Response.Build (MIME.Text_HTML, "10sec ok");

      else
         Put_Line ("Unknown URI " & URI);
         return Response.Build
           (MIME.Text_HTML, URI & " not found", Messages.S404);
      end if;
   end CB;

   ------------
   -- Server --
   ------------

   task body Server is
   begin
      AWS.Server.Start
        (HTTP, "Test Client Timeouts",
         CB'Unrestricted_Access, Port => 7645, Max_Connection => 5);

      Put_Line ("Server started");
      New_Line;

      accept Started;

      accept Stopped;

      AWS.Server.Shutdown (HTTP);
   exception
      when E : others =>
         Put_Line ("Server Error " & Exceptions.Exception_Information (E));
   end Server;

   -------------
   -- Request --
   -------------

   procedure Request is
      R : Response.Data;
   begin
      R := Client.Get ("http://localhost:7645/3sec", Timeouts => (1, 1));
      Put_Line ("=> " & Response.Message_Body (R));
      New_Line;

      R := Client.Get ("http://localhost:7645/3sec", Timeouts => (10, 10));
      Put_Line ("=> " & Response.Message_Body (R));
      New_Line;

      R := Client.Get ("http://localhost:7645/10sec", Timeouts => (1, 20));
      Put_Line ("=> " & Response.Message_Body (R));
      New_Line;

      R := Client.Get ("http://localhost:7645/10sec", Timeouts => (10, 7));
      Put_Line ("=> " & Response.Message_Body (R));
      New_Line;
   end Request;

   -------------------
   -- Alive_Request --
   -------------------

   procedure Alive_Request is
      R : Response.Data;
      Connect : Client.HTTP_Connection;
   begin
      Client.Create
        (Connection => Connect,
         Host       => "http://localhost:7645",
         Timeouts => (0, 5));

      Client.Get (Connect, R, "/3sec");
      Put_Line ("-> " & Response.Message_Body (R));
      New_Line;

      Client.Get (Connect, R, "/10sec");
      Put_Line ("-> " & Response.Message_Body (R));
      New_Line;

      Client.Get (Connect, R, "/3sec");
      Put_Line ("-> " & Response.Message_Body (R));
      New_Line;

      Client.Get (Connect, R, "/10sec");
      Put_Line ("-> " & Response.Message_Body (R));
      New_Line;

      Client.Close (Connect);
   end Alive_Request;

begin
   Put_Line ("Start main, wait for server to start...");

   Server.Started;

   Request;

   Alive_Request;

   Server.Stopped;

exception
   when E : others =>
      Put_Line ("Main Error " & Exceptions.Exception_Information (E));
      Server.Stopped;
end Tclientto;
