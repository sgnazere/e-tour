# e-Tour Côte d'Ivoire

Petit site pour choisir, entre amis, la prochaine ville de Côte d'Ivoire à visiter :
16 villes en tournoi « face-match », tendance de tous les participants,
puis réservation d'un week-end (vendredi → dimanche, entre le 25 et le 10 du mois suivant).

## Structure

```
site/                    ← publié par Netlify
  index.html             ← la page (ne pas modifier sauf évolution)
  config.js              ← URL + clé publique Supabase, liste des villes, photos
  images/                ← photos des villes (.webp ou .jpg)
database/
  supabase_securise.sql  ← schéma + fonctions de contrôle (à exécuter dans Supabase)
netlify.toml             ← dit à Netlify de publier seulement "site"
```

## Technique

- Front : HTML/CSS/JS sans framework, hébergé sur Netlify (gratuit).
- Base : Supabase (PostgreSQL). Le public n'a aucun accès direct aux tables :
  tout passe par les fonctions `inscrire`, `enregistrer_duels`, `reserver`,
  `renoncer`, `tendance`, `interet_dates`.
- Données collectées : un pseudo et un numéro WhatsApp, rien d'autre.

## Sécurité

- `config.js` contient uniquement la clé **publique** (publishable / anon) : elle est faite pour être visible.
- Ne jamais committer la clé `secret` / `service_role`, ni un export CSV des inscrits.

## Mettre à jour le site

Modifier un fichier sur GitHub → « Commit changes » → Netlify republie automatiquement en ~30 s.
