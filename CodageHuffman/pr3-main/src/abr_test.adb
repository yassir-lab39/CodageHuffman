with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with ABR; use ABR;

procedure Tester_ABR is

   Arbre : T_ABR;
   Valeur : Integer;

begin

   Initialiser(Arbre);
   
   Enregistrer(Arbre, 'A', 10);
   Enregistrer(Arbre, 'B', 20);
   Enregistrer(Arbre, 'C', 30);
   Enregistrer(Arbre, 'D', 40);

   Valeur := Taille(Arbre);
   pragma Assert(Valeur = 4, "Erreur : La taille de l'arbre devrait être 4.");

   Put_Line("Taille de l'arbre : " & Integer'Image(Valeur));

   Valeur := La_Valeur(Arbre, 'B');
   pragma Assert(Valeur = 20, "Erreur : La valeur pour la clé 'B' devrait être 20.");
   Put_Line("Valeur pour la clé 'B' : " & Integer'Image(Valeur));

   Valeur := La_Valeur(Arbre, 'A');
   pragma Assert(Valeur = 10, "Erreur : La valeur pour la clé 'A' devrait être 10.");
   Put_Line("Valeur pour la clé 'A' : " & Integer'Image(Valeur));

   Valeur := La_Valeur(Arbre, 'C');
   pragma Assert(Valeur = 30, "Erreur : La valeur pour la clé 'C' devrait être 30.");
   Put_Line("Valeur pour la clé 'C' : " & Integer'Image(Valeur));

   Valeur := La_Valeur(Arbre, 'D');
   pragma Assert(Valeur = 40, "Erreur : La valeur pour la clé 'D' devrait être 40.");
   Put_Line("Valeur pour la clé 'D' : " & Integer'Image(Valeur));

   Detruire(Arbre);

   if Est_Vide(Arbre) then
      Put_Line("L'arbre a été détruit avec succès.");
   else
      Put_Line("L'arbre n'a pas été détruit.");
   end if;

   pragma Assert(Est_Vide(Arbre), "Erreur : L'arbre n'est pas vide après destruction.");

   Put_Line("Test : OK");

end Tester_ABR;
