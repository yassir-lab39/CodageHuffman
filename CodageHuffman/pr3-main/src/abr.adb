with SDA_Exceptions;         use SDA_Exceptions;
with Ada.Unchecked_Deallocation;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body ABR is

   procedure Free is
     new Ada.Unchecked_Deallocation (Object => T_Noeud, Name => T_ABR);


   procedure Initialiser(Arbre: out T_ABR) is
   begin
      Arbre := null;
   end Initialiser;


   function Est_Vide (Arbre : T_ABR) return Boolean is
   begin
      return Arbre = null;
   end Est_Vide;


   function Taille (Arbre : in T_ABR) return Integer is
   begin
      if Arbre = null then
         return 0;
      else
         return 1 + Taille (Arbre.all.Sous_Arbre_Gauche)
           + Taille (Arbre.all.Sous_Arbre_Droit);
      end if;
   end Taille;


   procedure Enregistrer (Arbre : in out T_ABR ; Cle : in Unbounded_String ; Valeur : in Integer) is
   begin
      if Arbre = null then
         Arbre :=  new T_Noeud'(Cle, Valeur, null, null);
      elsif Arbre.all.Cle < Cle then
         Enregistrer (Arbre.all.Sous_Arbre_Droit, Cle, Valeur);
      elsif Cle < Arbre.all.Cle then
         Enregistrer (Arbre.all.Sous_Arbre_Gauche, Cle, Valeur);
      else
         Arbre.all.Valeur := Valeur;
      end if;
   end Enregistrer;

   procedure Detruire (Arbre : in out T_ABR) is
   begin
      if Arbre = null then
         null;
      else
         Detruire (Arbre.all.Sous_Arbre_Gauche);
         Detruire (Arbre.all.Sous_Arbre_Droit);
         Free (Arbre);
      end if;
   end Detruire;

end ABR;
