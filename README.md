# Script Banque NUI Moderne pour FiveM

> Un script banque ultra clean avec interface NUI moderne, full customisable et prêt à claquer en live.

---

## 🚀 Features

- Emplacements de banques et distributeurs ATM définis en config (avec coords réalistes)
- Bonus hebdo automatique (1000$ tous les 7 jours par défaut, modifiable)
- Blips personnalisés sur la map pour repérer les banques easy
- Props ATM variés (plus réaliste, plus vibe)
- Interface NUI moderne, fluide, customisable (HTML/CSS/JS)
- Cooldown, animations, et interactions aux petits oignons

---

## ⚙️ Installation

1. **Met dans ton dossier resources**  
   `git clone <ton-repo-url> banque-script`

2. **Ajoute dans ton `server.cfg`**

   ```plaintext
   ensure banque-script
   ```

3. **Importe la base SQL**  
   Dans ton outil de gestion de BDD (phpMyAdmin, HeidiSQL, whatever), importe `banking.sql` pour créer les tables nécessaires.

---

## 🛠️ Configuration

Tout est dans `config.lua`, simple comme bonjour :

- **Ajouter/modifier les emplacements des banques :**

```lua
Config.BankLocations = {
    { x = 149.70,   y = -1041.24, z = 29.37 },
    -- Ajoute/modifie les coordonnées ici
}
```

- **Changer les modèles d’ATM :**

```lua
Config.ATMProps = {
    `prop_atm_01`,
    `prop_atm_02`,
    `prop_atm_03`,
    `prop_fleeca_atm`,
}
```

- **Bonus hebdo :**

```lua
Config.WeeklyBonus = {
    amount = 1000,                  -- Montant du bonus
    cooldownTime = 7 * 24 * 60 * 60 -- Délai en secondes (ici 7 jours)
}
```

- **Blips sur la map :**

```lua
Config.Blips = {
    sprite = 500,
    display = 4,
    scale = 0.5,
    color = 2,
    shortRange = true,
    label = "Banque"
}
```

---

## 🎨 Personnalisation de l’interface

Les couleurs et textes sont dans les fichiers NUI :

- **HTML / CSS** :  
  Les couleurs sont gérées via les variables CSS dans `:root` du fichier `styles.css`.  
  Change-les pour coller à ton style :

```css
:root {
  --primary-container: #1c1c1c;
  --secondary-container: #141414;
  --text: #9243fa;
  --primary: #6900f3;
  --hover: #3f0091;
  --white: #dfdfdf;
  --positive: #55ff7f;
  --negative: #ff5555;
}
```

- **Textes / labels** :  
  Dans `index.html` ou directement dans les fichiers JS où le contenu est généré, tu peux modifier les textes pour changer la langue ou customiser l’UI.

---

## 🛢️ SQL

Le fichier `banking.sql` contient la structure de la base de données nécessaire, notamment pour gérer les comptes joueurs et les transactions.

---

## 🎥 Vidéo de présentation

[![Watch the video](https://img.youtube.com/vi/WPptJs9SUiw/maxresdefault.jpg)](https://youtu.be/WPptJs9SUiw?si=Vdqn8fQflS9lZ9rZ)

---

## 🤔 Pourquoi choisir ce script ?

- NUI moderne, responsive, fluide (fini les interfaces à l’ancienne qui te donnent mal aux yeux)
- Complètement customisable, tu modifies tout : emplacements, blips, bonus, visuels
- Intégré à ta base SQL pour une gestion solide
- Facile à déployer, juste quelques config à toucher si tu souhaite la personnaliser et hop ça roule

---

## ❓ FAQ / ToDo

- Comment ajouter un nouveau distributeur ou une nouvelle banque?  
  Ajoute juste un nouveau coord dans `Config.BankLocations` ou `Config.ATMProps`.

- Je veux changer le style des boutons, comment ?  
  Dans `styles.css` tu as tout le contrôle, profite-en.

- Support multi-langues ?  
  Pas encore, mais tu peux modifier les textes dans le HTML/JS à ta sauce.

---

## Licence

MIT — Fais ce que tu veux, mais garde le crédit, c’est cool.
