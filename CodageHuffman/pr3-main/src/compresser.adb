with ABR;       use ABR;
with Ada.Streams.Stream_IO; use Ada.Streams.Stream_IO;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Command_Line;     use Ada.Command_Line;

procedure Compresser is
   type T_Element is
      record
         Cle : Unbounded_String;
         Frequence : Integer;
      end record;

   type T_Tab is array(1..256) of T_Element;
   C : Character;
   Tableau : T_Tab := (others => (Cle => To_Unbounded_String("/"), Frequence => 0));
   S1 : String(1..1);

   File_Name : Unbounded_String;
   File      : Ada.Streams.Stream_IO.File_Type;
   S         : Stream_Access;
   type T_Octet is mod 2**8;
   for T_Octet'Size use 8;
   Octet     : T_Octet;

   -- Enregistrement des symboles utilisés et leur nombre d'occurence

   procedure Frequence(File_Name : String) is
   begin
      Open(File, In_File, File_Name);
      S := Stream(File);
      while not End_Of_File(File) loop
         Octet := T_Octet'Input(S);
         C:= Character'Val(Octet);
         for i in 1..256 loop
            S1(1) := C;
            if Tableau(i).Frequence = 0 then
               Tableau(i).Cle := To_Unbounded_String(S1);
               Tableau(i).Frequence := 1;
               exit;
            elsif Tableau(i).Cle = To_Unbounded_String(S1) then
               Tableau(i).Frequence := Tableau(i).Frequence + 1;
               exit;
            end if;
         end loop;
      end loop;
      Close (File);
   end Frequence;

   -- fonction qui retourne le nombre de symboles utilisés
   function Taille(Tableau : in T_Tab) return Integer is
      nb : Integer := 0;
   begin
      for i in 1..Tableau'Length loop
         if Tableau(i).Frequence = 0 then
            exit;
         end if;
         nb := nb + 1;
      end loop;
      return nb;
   end Taille;

   type T_Tab_Abr is array(Positive range <>) of T_ABR;

   -- fonction qui retourne un tableau avec tous les noeuds(feuilles) de l'arbre de huffman

   function Tableau_Des_Arbre(Tableau : in T_Tab; Taille : in Integer) return T_Tab_Abr is
      Tab_Abr : T_Tab_Abr(1..256);
   begin
      for i in 1..Taille loop
         Initialiser(Tab_Abr(i));
         Tab_Abr(i) := New T_Noeud'(Tableau(i).Cle, Tableau(i).Frequence, null, null);
      end loop;
      Tab_Abr(Taille+1) := new T_Noeud'(To_Unbounded_String("\$"), 0, null, null);
      return Tab_Abr;
   end Tableau_Des_Arbre;

   -- fonction qui retourne l'indice du noeud avec la plus petite frequence
   function Ind_Min(Tab_Abr : in out T_Tab_Abr; Size : in Integer) return Integer is
      Indice : Integer := 1;
   begin
      for i in 1..Size loop
         if Tab_Abr(i).Valeur < Tab_Abr(Indice).Valeur then
            Indice := i;
         end if;
      end loop;
      return Indice;
   end Ind_Min;

   n : Integer;
   Tab : T_Tab_Abr(1..256);

   --Creation de l'arbre de huffman a partir de tableau des noeuds 
   function Arbre_De_Huffman(Tab_Abr : in out T_Tab_Abr) return T_ABR is
      Arbre : T_ABR := null;
      size : Integer := 0;
      Indice1 : Integer;
      Indice2 : Integer;
      Nouveau_Noeud : T_ABR;
   begin
      for i in 1..256 loop
         if Tab_Abr(i).Valeur = 0 then
            exit;
         end if;
         size := size + 1;
      end loop;
      size := size + 1;
      while size > 1 loop
         Indice1 := Ind_Min(Tab_Abr, size);
         declare
            Copie : T_ABR;
         begin
            Copie := Tab_Abr(Indice1);
            Tab_Abr(Indice1) := Tab_Abr(size);
            Tab_Abr(size) := Copie;
         end;
         size := size -1;
         Indice2 := Ind_Min(Tab_Abr, size);
         declare
            Copie : T_ABR;
         begin
            Copie := Tab_Abr(Indice2);
            Tab_Abr(Indice2) := Tab_Abr(size);
            Tab_Abr(size) := Copie;
         end;
         Nouveau_Noeud := new T_Noeud'(To_Unbounded_String("/"), Tab_Abr(size).Valeur + Tab_Abr(size+1).Valeur, Tab_Abr(size),Tab_Abr(size+1));
         Tab_Abr(size) := Nouveau_Noeud;
      end loop;
      Arbre := Tab_Abr(1);
      return Arbre;
   end Arbre_De_Huffman;

   -- affichage de l'arbre
   procedure Afficher_Arbre_Bis(Arbre : T_ABR; prefix : String; Indent : String) is
      Arbre_Courant : T_ABR;
   begin
      if Arbre.Sous_Arbre_Gauche /= Null then
         Arbre_Courant := Arbre.Sous_Arbre_Gauche;
         if Arbre_Courant.Sous_Arbre_Gauche = Null and Arbre_Courant.Sous_Arbre_Droit = Null then
            if To_String(Arbre_Courant.Cle)(1) = ASCII.LF then
               Put_Line(Indent & "\--0--" & "(" & Integer'Image(Arbre_Courant.Valeur)(2..Integer'Image(Arbre_Courant.Valeur)'Length) & ")" & " '" & '\' & 'n' & "'");
            else
               Put_Line(Indent & "\--0--" & "(" & Integer'Image(Arbre_Courant.Valeur)(2..Integer'Image(Arbre_Courant.Valeur)'Length) & ")" & " '" & To_String(Arbre_Courant.Cle) & "'");
            end if;
         else
            Put_Line(Indent & "\--0--" & "(" & Integer'Image(Arbre_Courant.Valeur)(2..Integer'Image(Arbre_Courant.Valeur)'Length) & ")");
            Afficher_Arbre_Bis(Arbre.Sous_Arbre_Gauche, prefix, Indent & "|      ");
         end if;
      end if;
      if Arbre.Sous_Arbre_Droit /= Null then
         Arbre_Courant := Arbre.Sous_Arbre_Droit;
         if Arbre_Courant.Sous_Arbre_Gauche = Null and Arbre_Courant.Sous_Arbre_Droit = Null then
            if To_String(Arbre_Courant.Cle)(1) = ASCII.LF then
               Put_Line(Indent & "\--1--" & "(" & Integer'Image(Arbre_Courant.Valeur)(2..Integer'Image(Arbre_Courant.Valeur)'Length) & ")" & " '" & '\' & 'n' & "'");
            else
               Put_Line(Indent & "\--1--" & "(" & Integer'Image(Arbre_Courant.Valeur)(2..Integer'Image(Arbre_Courant.Valeur)'Length) & ")" & " '" & To_String(Arbre_Courant.Cle) & "'");
            end if;
         else
            Put_Line(Indent & "\--1--" & "(" & Integer'Image(Arbre_Courant.Valeur)(2..Integer'Image(Arbre_Courant.Valeur)'Length) & ")");
            Afficher_Arbre_Bis(Arbre.Sous_Arbre_Droit, prefix, Indent & "       ");
         end if;
      end if;
   end Afficher_Arbre_Bis;

   procedure Afficher_Arbre(Arbre : in T_ABR) is
   begin
      if Arbre = null then
         Put_Line("L'arbre est vide");
         return;
      end if;
      Put_Line("(" & Integer'Image(Arbre.Valeur)(2..Integer'Image(Arbre.Valeur)'Length) & ")");
      Afficher_Arbre_Bis(Arbre, "", "");
   end Afficher_Arbre;

   Arbre : T_ABR;
   type T_Couple is
      record
         Cle : Unbounded_String;
         Valeur : Unbounded_String;
      end record;

   type T_Tab_Octet is array(1..256) of T_Couple;
   Indice : Integer := 1;

   -- le codage de chaque symbole a partir de l'arbre de huffman
   procedure Codage(Arbre : in T_ABR; code_courant : in out Unbounded_String; Tableau_Octet : in out T_tab_Octet) is
      C : Unbounded_String;
   begin
      if Arbre.Sous_Arbre_Gauche = null and Arbre.Sous_Arbre_Droit = null then
         Tableau_Octet(Indice).Cle := Arbre.Cle;
         Tableau_Octet(Indice).Valeur := code_courant;
         Indice := Indice + 1;
      end if;
      if Arbre.Sous_Arbre_Gauche /= null then
         C := code_courant & "0";
         Codage(Arbre.Sous_Arbre_Gauche, C, Tableau_Octet);
      end if;
      if Arbre.Sous_Arbre_Droit /= null then
         C := code_courant & "1";
         Codage(Arbre.Sous_Arbre_Droit, C, Tableau_Octet);
      end if;
   end Codage;

   function Affichage_Tableau(Tableau_Octet : in T_Tab_Octet; Size : in Integer) return Unbounded_String is
      S : Unbounded_String;
   begin
      for i in 1..(Size+1) loop
         S := S & "'";
         if To_String(Tableau_Octet(i).Cle)(1) = ASCII.LF then
            S := S & '\' & 'n';
         elsif To_String(Tableau_Octet(i).Cle) = "\$" then
            S := S & '\' & '$';
         else
            S := S & To_String(Tableau_Octet(i).Cle);
         end if;
         S := S & "'  --> " & To_String(Tableau_Octet(i).Valeur) & ASCII.LF;
      end loop;
      return S;
   end Affichage_Tableau;


   function Affichage_Texte(Tableau_Octet : in T_Tab_Octet; Size : in Integer) return Unbounded_String is
      Str : Unbounded_String;
   begin
      Open(File, In_File, To_String(File_Name));
      S := Stream(File);
      while not End_Of_File(File) loop
         Octet := T_Octet'Input(S);
         C:= Character'Val(Octet);
         --New_Line;
         for i in 1..(Size+1) loop
            if To_String(Tableau_Octet(i).Cle)(1) = C then
               --Put_Line("this is val ");
               --Put(To_String(Tableau_Octet(i).Valeur));
               --New_Line;
               Str := Str & To_String(Tableau_Octet(i).Valeur);
               exit;
            end if;
         end loop;
      end loop;
      Close (File);
      return To_Unbounded_String(To_String(Str)(1..Length(Str)-1));
   end Affichage_Texte;

   type T_Symbole is array(1..256) of Integer;
   type T_Tableau is
      record
         Tab_Symbole : T_Symbole;
         Taille : Integer;
      end record;

   -- un parcours infixe de l'arbre pour creer le code de l'arbre et la liste des symboles en octet 
   procedure Parcours_Infixe(Arbre : out T_ABR; Code_arbre : in out Unbounded_String; TabDesSymboles : in out T_Tableau) is
   begin
      if Arbre.Sous_Arbre_Gauche /= Null then
         Code_arbre := Code_arbre & "0";
         Parcours_Infixe(Arbre.Sous_Arbre_Gauche, Code_arbre, TabDesSymboles);
      end if;
      if Arbre.Sous_Arbre_Droit /= Null then
         Code_arbre := Code_arbre & "1";
         Parcours_Infixe(Arbre.Sous_Arbre_Droit, Code_arbre, TabDesSymboles);
      end if;
      if Arbre.Sous_Arbre_Gauche = Null and Arbre.Sous_Arbre_Droit = Null and To_String(Arbre.Cle) /= "\$" then
         TabDesSymboles.Taille := TabDesSymboles.Taille + 1;
         TabDesSymboles.Tab_Symbole(TabDesSymboles.Taille) := Character'Pos(To_String(Arbre.Cle)(1));
      end if;
      if To_String(Arbre.Cle) = "\$" then
         TabDesSymboles.Taille := TabDesSymboles.Taille + 1;
         TabDesSymboles.Tab_Symbole(TabDesSymboles.Taille) := -1;
      end if;
   end Parcours_Infixe;

   -- mettre l'indice de \$ dans le premier element du tableau
   procedure Tableau_Symboles (TabDesSymboles : in out T_Tableau) is
      Indice_fin : Integer := 1;
      copie : Integer;
   begin
      while TabDesSymboles.Tab_Symbole(Indice_fin) /= -1 loop
         Indice_fin := Indice_fin + 1;
      end loop;
      for i in 1..Indice_fin loop
         copie := TabDesSymboles.Tab_Symbole(Indice_fin);
         TabDesSymboles.Tab_Symbole(Indice_fin) := TabDesSymboles.Tab_Symbole(i);
         TabDesSymboles.Tab_Symbole(i) := copie;
      end loop;
      TabDesSymboles.Tab_Symbole(1) := Indice_fin;
      TabDesSymboles.Tab_Symbole(TabDesSymboles.Taille+1) := TabDesSymboles.Tab_Symbole(TabDesSymboles.Taille);
      TabDesSymboles.Taille := TabDesSymboles.Taille + 1;
   end Tableau_Symboles;

   -- passage de 8 bits a un octet
   function Horner(code : in Unbounded_String) return Integer is
      n : Integer := 0;
   begin
      for i in 1..8 loop
         if To_String(code)(i) = '1' then
            n := n + 2**(8-i);
         end if;
      end loop;
      return n;
   end Horner;

   --passage d'un octet a 8 bits
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

   -- creation du fichier File_Name.hff
   procedure Creation(File_Name : String; TabDesSymboles : in T_Tableau; Tableau_Octet : in T_Tab_Octet; Size : in Integer; Code_arbre : in out Unbounded_String) is
      File : Ada.Streams.Stream_IO.File_Type;
      S : Stream_Access;
      S1,S2 : Unbounded_String;
      n : Integer;
   begin
      Create(File, Out_File, File_Name & ".hff");
      S := Stream(File);
      S1 := Affichage_Texte(Tableau_Octet,Size);
      S2 := Code_arbre & "1";
      for i in 1..TabDesSymboles.Taille loop
         T_Octet'Write(S, T_Octet(TabDesSymboles.Tab_Symbole(i)));
      end loop;
      n := To_String(S2)'Length mod 8;
      if n /= 0 then
         for i in n..7 loop
            S2 := S2 & "0";
         end loop;
      end if;
      for i in 1..To_String(S2)'Length loop
         if i mod 8 = 1 then
            T_Octet'Write(S, T_Octet(Horner(To_Unbounded_String(To_String(S2)(i..i+7)))));
         end if;
      end loop;
      for i in 1..256 loop
         if To_String(Tableau_Octet(i).Cle) = "\$" then
            S1 := S1 & To_String(Tableau_Octet(i).Valeur);
         end if;
      end loop;
      n := To_String(S1)'Length mod 8;
      if n /= 0 then
         for i in n..7 loop
            S1 := S1 & "0";
         end loop;
      end if;
      for i in 1..To_String(S1)'Length loop
         if i mod 8 = 1 then
            T_Octet'Write(S, T_Octet(Horner(To_Unbounded_String(To_String(S1)(i..i+7)))));
         end if;
      end loop;
      Close(File);
   end Creation;

   Tableau_Octet : T_Tab_Octet;
   Str : Unbounded_String := To_Unbounded_String("");
   Code_arbre : Unbounded_String := To_Unbounded_String("");
   TabDesSymboles : T_Tableau;
   
begin
   If Argument_Count = 0 then
      Put_Line("il faut indiquer le fichier");
      return;
   end if;
   File_Name := To_Unbounded_String(Argument (Argument_Count));
   Frequence(To_String(File_Name));
   n := Taille(Tableau);
   Tab := Tableau_Des_Arbre(Tableau, n);
   Arbre := Arbre_De_Huffman(Tab);
   Codage(Arbre, Str, Tableau_Octet);
   if Argument_Count > 1 then
      if Argument(Argument_Count-1) /= "-s" and Argument(Argument_Count-1) /= "--silencieux" then
         Afficher_Arbre(Arbre);
         New_Line;
         Put(To_String(Affichage_Tableau(Tableau_Octet, n)));
      end if;
   end if;
   if Argument_Count = 1 then
      Afficher_Arbre(Arbre);
      New_Line;
      Put(To_String(Affichage_Tableau(Tableau_Octet, n)));
   end if;
   TabDesSymboles.Taille := 0;
   TabDesSymboles.Tab_Symbole := ( others => 0 );
   Parcours_Infixe(Arbre, Code_arbre, TabDesSymboles);
   Tableau_Symboles(TabDesSymboles);
   Creation(To_String(File_Name), TabDesSymboles, Tableau_Octet, n, Code_arbre);
   Detruire(Arbre);
end Compresser;

















