// =====================================================================
//  e-Tour Côte d'Ivoire — CONFIGURATION
//  C'est le SEUL fichier à modifier.
// =====================================================================

// 1) Colle ici ton URL Supabase (bouton "Connect" ou Project Settings > Data API)
const SUPABASE_URL = "https://rolxizekhlhkfuhdjwdy.supabase.co";

// 2) Colle ici ta clé PUBLIQUE (publishable "sb_publishable_..." ou "anon public")
//    Ne mets JAMAIS la clé "secret" ou "service_role".
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJvbHhpemVraGxoa2Z1aGRqd2R5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIyNDg0NjgsImV4cCI6MjEwNzgyNDQ2OH0.UGePcCmEvDFm3uXu_WG41VNnCKlou-AKDVg9ql0l5sk";

// 3) Les villes (16 exactement pour le tournoi).
//    photo : chemin vers ta photo dans le dossier images (laisse "" pour garder l'illustration)
//    credit : auteur ou source de la photo (obligatoire si tu mets une photo)
const CITIES = [
  { n: "Assinie",        z: "Littoral", r: "Sud-Comoé",        t: "Lagune, plages et sports nautiques",        km: 85,  s: "assinie",     photo: "", credit: "" },
  { n: "Grand-Bassam",   z: "Littoral", r: "Sud-Comoé",        t: "Quartier France classé UNESCO",              km: 40,  s: "bassam",      photo: "", credit: "" },
  { n: "Jacqueville",    z: "Littoral", r: "Grands-Ponts",     t: "Pont sur la lagune, plages calmes",          km: 60,  s: "jacqueville", photo: "", credit: "" },
  { n: "Grand-Béréby",   z: "Littoral", r: "San-Pédro",        t: "Baie sauvage, tortues marines",              km: 420, s: "bereby",      photo: "", credit: "" },
  { n: "San-Pédro",      z: "Littoral", r: "San-Pédro",        t: "Port, plage de Monogaga",                    km: 350, s: "port",        photo: "", credit: "" },
  { n: "Sassandra",      z: "Littoral", r: "Gbôklé",           t: "Vieux phare, plages et pêche",               km: 270, s: "phare",       photo: "", credit: "" },
  { n: "Fresco",         z: "Littoral", r: "Gbôklé",           t: "Lagune, mangrove et pirogues",               km: 200, s: "fresco",      photo: "", credit: "" },
  { n: "Yamoussoukro",   z: "Centre",   r: "Lacs",             t: "Basilique Notre-Dame de la Paix",            km: 240, s: "basilique",   photo: "", credit: "" },
  { n: "Bouaké",         z: "Centre",   r: "Gbêkê",            t: "Grand marché, carnaval, tissage baoulé",     km: 350, s: "marche",      photo: "", credit: "" },
  { n: "Daloa",          z: "Ouest",    r: "Haut-Sassandra",   t: "Cité du cacao, forêts et marchés",           km: 380, s: "daloa",       photo: "", credit: "" },
  { n: "Soubré",         z: "Ouest",    r: "Nawa",             t: "Chutes de la Nawa et grand barrage",         km: 400, s: "soubre",      photo: "", credit: "" },
  { n: "Man",            z: "Ouest",    r: "Tonkpi",           t: "Cascades, Dent de Man, ponts de lianes",     km: 575, s: "man",         photo: "", credit: "" },
  { n: "Abengourou",     z: "Est",      r: "Indénié-Djuablin", t: "Palais royal de l'Indénié, culture agni",    km: 210, s: "palais",      photo: "", credit: "" },
  { n: "Korhogo",        z: "Nord",     r: "Poro",             t: "Toiles de Korhogo, villages sénoufo",        km: 600, s: "korhogo",     photo: "", credit: "" },
  { n: "Ferkessédougou", z: "Nord",     r: "Tchologo",         t: "Champs de canne, savane du Nord",            km: 580, s: "ferke",       photo: "", credit: "" },
  { n: "Odienné",        z: "Nord",     r: "Kabadougou",       t: "Mont Denguélé, mosquée soudanaise",          km: 850, s: "odienne",     photo: "", credit: "" }
];
// Exemple avec photo :  photo: "images/assinie.webp", credit: "Photo : Côte d'Ivoire Tourisme"
