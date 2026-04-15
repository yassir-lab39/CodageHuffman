with Ada.Streams.Stream_IO; use Ada.Streams.Stream_IO;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Command_Line;     use Ada.Command_Line;

procedure decompresser is
   File_Name : Unbounded_String;
   File      : Ada.Streams.Stream_IO.File_Type;
   S         : Stream_Access;
   type T_Octet is mod 2**8;
   for T_Octet'Size use 8;
   Octet     : T_Octet;

   type T_Tab is array(1..256) of Integer;
   type T_Couple is
      record
         Cle : Unbounded_String;-- character
         Valeur : Unbounded_String;--symbol in huffman
      end record;

   type T_Tab_Octet is array(1..256) of T_Couple;

   function OctetTo8Bits (n : in Integer) return String is
      S : Unbounded_String := To_Unbounded_String("");
      copie : Integer := n;
   begin
      for i in 1..8 loop
         if copie >= 2**(8-i) then
            S := S & "1";
            copie := copie - 2**(8-i);
         else
            S := S & "0";
         end if;
      end loop;
      return To_String(S)(1..8);
   end OctetTo8Bits;

   -- la lecture du fichier binaire et l'obtention du tableau de symbole et un string qui contient le code de l'arbre et le texte
   procedure Lire (File_Name : String; Tableau : in out T_Tab; S1 : in out Unbounded_String) is
      nb : Integer := 1;
      char_finish : Boolean := False;
   begin
      Open(File, In_File, File_Name);
      S := Stream(File);
      while not End_Of_File(File) loop
         Octet := T_Octet'Input(S);
         if char_finish = False then
            Tableau(nb) := Integer(Octet);
            if nb > 1 and then Tableau(nb) = Tableau(nb-1) then
                 Tableau(nb) := -1;
                 char_finish := True;
            end if;
         nb := nb +  1;
         end if;

         if char_finish then
            S1 := S1 & OctetTo8Bits(Integer(Octet));
         end if;
      end loop;
      S1 := To_Unbounded_String(To_String(S1)(9..To_String(S1)'Length));
      Close(File);
   end Lire;

   -- trouver le code (l'arbre de huffman) de chaque symbole et la separation du code de l'arbre et le texte 
   procedure extract_symbols(Symbols : in T_Tab; S : in out Unbounded_String; code_chars : in out T_Tab_Octet; nb_chars : in Integer) is
      indice_dollar : Integer;
      indice_char : Integer  := 1;
      indice : Integer := 1 ;
      symbol_courant : Unbounded_String;
      s1 : string(1..1);
   begin
      -- structure t tab int chaque element correspondance char => hyffman symbol
      indice_dollar := Symbols(1);
      while indice_char <= nb_chars loop
         symbol_courant := symbol_courant & To_String(S)(indice);
         if To_String(S)(indice+1) = '1' then
            if indice_char = indice_dollar then
               code_chars(indice_char).Cle := To_Unbounded_String("\$");
               code_chars(indice_char).Valeur  := symbol_courant;
            else
               s1(1) := Character'Val(Symbols(indice_char));
               if indice_char < indice_dollar then
                  s1(1) := Character'Val(Symbols(indice_char+1));
               end if;
               code_chars(indice_char).Cle := To_Unbounded_String(s1);
               code_chars(indice_char).Valeur  := symbol_courant;

            end if;
            indice_char := indice_char + 1;
            if indice_char <= nb_chars then
               while To_String(symbol_courant)(To_String(symbol_courant)'Length) /= '0' loop
                  symbol_courant := To_Unbounded_String(To_String(symbol_courant)(1..length(symbol_courant)-1));
               end loop;
               symbol_courant := To_Unbounded_String(To_String(symbol_courant)(1..length(symbol_courant)-1));-- la feuille 0001 lle 00
            end if;
         end if;
         indice := indice + 1;
      end loop;
      if indice mod 8 /= 0 then
         indice := indice + 8 - (indice mod 8);
      end if;
      S := To_Unbounded_String(To_String(S)(indice+1..length(S)));
   end extract_symbols;

   -- recuperation du texte final
   function extract_texte(S: in Unbounded_String; code_chars : in T_Tab_Octet) return String is
      string_courant : Unbounded_String := To_Unbounded_String("");
      indice : Integer := 1 ;
      Resultat : Unbounded_String := To_Unbounded_String("");
      a : Boolean := True;
   begin
      while a and indice < Length(S) loop
         string_courant := string_courant & To_String(S)(indice);
         for i in 1..256 loop
            if code_chars(i).Valeur = string_courant then
               Resultat := Resultat & code_chars(i).Cle;
               string_courant := To_Unbounded_String("");
               exit;
            end if;
         end loop;
         if Length(Resultat) > 1 and then To_String(Resultat)(Length(Resultat)-1..Length(Resultat)) = "\$" then
            a := False;
         end if;
         indice :=  indice + 1;
      end loop;
      return To_String(Resultat);
   end extract_texte;

   -- creation du fichier File_Name.d 
   File1 : Ada.Text_IO.File_Type;
   procedure Creation (File_Name : in String; S: in Unbounded_String; code_chars : in T_Tab_Octet) is
      Str : Unbounded_String;
   begin
      Str := To_Unbounded_String(extract_texte(S, code_chars));
      Create(File1, Out_File, File_Name & ".d");
      Put(File1, To_String(Str));
      Close(File1);
   end Creation;

   Arbre_Texte : Unbounded_String := To_Unbounded_String("");
   Tableau : T_Tab := (others => 0);
   size : Integer := 0;
   code_chars : T_Tab_Octet;
begin
   if Argument_Count = 1 then
      File_Name := To_Unbounded_String(Argument(1));
      Lire(To_String(File_Name), Tableau, Arbre_Texte);
   end if;
   for i in 1..256 loop
      size := size + 1 ;
      if Tableau(i) = -1 then
         exit;
      end if;
   end loop;
   size := size -1;
   extract_symbols(Tableau, Arbre_Texte, code_chars, size);
   Creation(To_String(File_Name), Arbre_Texte, code_chars);

end decompresser;
