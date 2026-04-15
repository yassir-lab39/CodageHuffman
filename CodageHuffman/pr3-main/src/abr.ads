-- Définition de structures de données associatives sous forme d'un arbre
-- binaire de recherche (ABR).
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package ABR is

   type T_Noeud;
   type T_ABR is access T_Noeud;
   type T_Noeud is
      record
         Cle: Unbounded_String;
         Valeur : Integer;
         Sous_Arbre_Gauche : T_ABR;
         Sous_Arbre_Droit : T_ABR;
      end record;

   procedure Initialiser(Arbre: out T_ABR);

   procedure Detruire (Arbre : in out T_ABR);

   function Est_Vide (Arbre : in T_ABR) return Boolean;

   function Taille (Arbre : in T_ABR) return Integer;


end ABR;
