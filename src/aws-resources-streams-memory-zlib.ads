------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                            Copyright (C) 2003                            --
--                                ACT-Europe                                --
--                                                                          --
--  Authors: Dmitriy Anisimkov - Pascal Obry                                --
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
--  covered by the GNU Public License.                                      --
------------------------------------------------------------------------------

--  $RCSfile$
--  $Revision$
--  $Date$
--  $Author$

--  This API is used as for standard memory stream (see parent package), the
--  only difference is that the stream is compressed.

with ZLib;

package AWS.Resources.Streams.Memory.ZLib is

   package ZL renames Standard.ZLib;

   type Stream_Type is new Memory.Stream_Type with private;

   subtype Window_Bits_Type   is ZL.Window_Bits_Type;
   subtype Header_Type        is ZL.Header_Type;
   subtype Compression_Level  is ZL.Compression_Level;
   subtype Strategy_Type      is ZL.Strategy_Type;
   subtype Compression_Method is ZL.Compression_Method;
   subtype Memory_Level_Type  is ZL.Memory_Level_Type;

   Default_Compression : constant Compression_Level := ZL.Default_Compression;

   procedure Deflate_Initialize
     (Resource     : in out Stream_Type;
      Level        : in     Compression_Level  := ZL.Default_Compression;
      Strategy     : in     Strategy_Type      := ZL.Default_Strategy;
      Method       : in     Compression_Method := ZL.Deflated;
      Window_Bits  : in     Window_Bits_Type   := ZL.Default_Window_Bits;
      Memory_Level : in     Memory_Level_Type  := ZL.Default_Memory_Level;
      Header       : in     Header_Type        := ZL.Default);
   pragma Inline (Deflate_Initialize);
   --  Initialize the compression

   procedure Inflate_Initialize
     (Resource    : in out Stream_Type;
      Window_Bits : in     Window_Bits_Type := ZL.Default_Window_Bits;
      Header      : in     Header_Type      := ZL.Default);
   pragma Inline (Inflate_Initialize);
   --  Initialize the decompression

   procedure Append
     (Resource : in out Stream_Type;
      Buffer   : in     Stream_Element_Array);
   --  Compress and Append Buffer into the memory stream

   procedure Read
     (Resource : in out Stream_Type;
      Buffer   :    out Stream_Element_Array;
      Last     :    out Stream_Element_Offset);
   --  Returns a chunck of data in Buffer, Last point to the last element
   --  returned in Buffer.

   function Size (Resource : in Stream_Type) return Stream_Element_Offset;
   --  Returns the number of bytes in the memory stream

   procedure Close (Resource : in out Stream_Type);
   --  Close the ZLib stream, release all memory associated with the Resource
   --  object.

   function Is_Compressed (Resource : in Stream_Type) return Boolean;
   --  Returns True

private

   type Stream_Access is access all Stream_Type;

   type Stream_Type is new Memory.Stream_Type with record
      Self    : Stream_Access := Stream_Type'Unchecked_Access;
      --  We need it for auto flush in the Size routine call

      Filter  : ZL.Filter_Type;
      Flushed : Boolean;
   end record;

end AWS.Resources.Streams.Memory.ZLib;
