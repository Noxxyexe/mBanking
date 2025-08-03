// Initialisation des variables globales
let playerMoney = 0;
let playerCash = 0;
let playerName = "John Doe";
let cardNumber = "1234 5678 **** 3456";
let cardDate = "02/32";
let transactionHistory = [];
let lastBonusClaim = 0;
let currentMonth = 2; // Mois par défaut (Mars = 2 car indexé à partir de 0)
let updateInterval = null;

// Tableau des noms de mois
const monthNames = [
    "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
    "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"
];
// console.log("Initialisation du script, mois par défaut:", currentMonth, "(", monthNames[currentMonth], ")");


// Au chargement de la page
window.addEventListener('load', () => {
    // Mise à jour de l'heure
    updateTime();
    // Actualiser l'heure chaque minute
    setInterval(updateTime, 60000);

    // Événements des boutons
    setupEventListeners();

    // Demande des données initiales
    fetchInitialData();

    // Fermeture de l'interface
    document.querySelector('.container-leave button').addEventListener('click', () => {
        closeUI();
    });
});

// Mise à jour de l'heure
function updateTime() {
    const now = new Date();
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    document.querySelector('.hour span').textContent = `${hours}:${minutes}`;
}

// Configuration des écouteurs d'événements pour les boutons
function setupEventListeners() {

    // Dépôt
    document.querySelector('.deposit-input button').addEventListener('click', ()=> {
            const amount=parseInt(document.querySelector('.deposit-input input').value);

            if (amount && amount > 0) {
                depositMoney(amount);
                document.querySelector('.deposit-input input').value='';
            }
        }

    );

    // Retrait
    document.querySelector('.withdraw-input button').addEventListener('click', ()=> {
            const amount=parseInt(document.querySelector('.withdraw-input input').value);

            if (amount && amount > 0) {
                withdrawMoney(amount);
                document.querySelector('.withdraw-input input').value='';
            }
        }

    );

    // Transfert
    document.querySelector('.transfer-input button').addEventListener('click', ()=> {
            const amount=parseInt(document.querySelector('.input-transfer-amount').value);
            const targetId=document.querySelector('.input-transfer-id').value;

            if (amount && amount > 0 && targetId) {
                transferMoney(amount, targetId);
                document.querySelector('.input-transfer-amount').value='';
                document.querySelector('.input-transfer-id').value='';
            }
        }

    );

    // Bonus hebdomadaire
    document.querySelector('.weekly-bonus button').addEventListener('click', ()=> {
            claimWeeklyBonus();
        }

    );
}

// Récupération des données initiales
function fetchInitialData() {
    // console.log("Récupération des données initiales...");
    
    fetch('https://mBanking/getInitialData', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    })
    .then(resp => resp.json())
    .then(data => {
        // console.log("Données initiales reçues:", data);
        if (data.currentMonth !== undefined) {
            // console.log("Mois initial:", data.currentMonth);
        }
        updateUIWithData(data);
        
        // Après mise à jour, vérifier si le mois est correct
        // console.log("Après mise à jour - Mois actuel:", currentMonth, "Nom du mois:", monthNames[currentMonth]);
        
        // Forcer la mise à jour des éléments du mois au cas où
        const receiptElem = document.getElementById('info-receipt');
        const coinsElem = document.getElementById('info-coins');
        
        if (receiptElem) {
            receiptElem.innerHTML = `Argent sur vous`;
        }
        
        if (coinsElem) {
            coinsElem.innerHTML = `Total`;
        }
    })
    .catch(error => {
        console.error("Erreur lors de la récupération des données initiales:", error);
    });
}

// Mise à jour de l'interface avec les données reçues
function updateUIWithData(data) {
    // Vérifier si les données sont valides avant de mettre à jour
    if (!data) return;

    // Mettre à jour les variables globales seulement si les nouvelles valeurs sont valides
    if (data.money !== undefined) playerMoney = data.money;
    if (data.cash !== undefined) playerCash = data.cash;
    if (data.name !== undefined) playerName = data.name;
    if (data.cardNumber !== undefined) cardNumber = data.cardNumber;
    if (data.cardDate !== undefined) cardDate = data.cardDate;
    if (data.transactions !== undefined) transactionHistory = data.transactions;
    if (data.lastBonusClaim !== undefined) lastBonusClaim = data.lastBonusClaim;

    // Si on reçoit le mois actuel du serveur, mettre à jour
    if (data.currentMonth !== undefined) {
        const monthIndex = parseInt(data.currentMonth);
        currentMonth = (monthIndex >= 1 && monthIndex <= 12) ? monthIndex - 1 : 0;
    }

    // Mise à jour des informations de carte
    document.getElementById('card-name').textContent = playerName;
    document.getElementById('card-number').textContent = cardNumber;
    document.getElementById('card-date').textContent = cardDate;

    // Mise à jour des textes et valeurs
    const walletElement = document.getElementById('info-wallet');
    const walletValueElement = document.getElementById('info-wallet-value');
    const receiptElement = document.getElementById('info-receipt');
    const receiptValueElement = document.getElementById('info-receipt-value');
    const coinsElement = document.getElementById('info-coins');
    const coinsValueElement = document.getElementById('info-coins-value');

    if (walletElement) {
        walletElement.textContent = "Argent en banque";
    }
    if (walletValueElement) {
        walletValueElement.textContent = formatMoney(playerMoney);
    }

    if (receiptElement) {
        receiptElement.innerHTML = `Argent sur vous`;
    }
    if (receiptValueElement) {
        receiptValueElement.textContent = formatMoney(playerCash);
    }

    if (coinsElement) {
        coinsElement.innerHTML = `Total`;
    }
    if (coinsValueElement) {
        coinsValueElement.textContent = formatMoney(playerMoney + playerCash);
    }

    // Mise à jour de l'historique des transactions
    updateTransactionHistory();

    // Vérification de la disponibilité du bonus hebdomadaire
    checkWeeklyBonusAvailability();
}

// Formatage des valeurs monétaires
function formatMoney(value) {
    // S'assurer que value est un nombre
    if (value === undefined || value === null) {
        value = 0;
    }
    // Convertir en nombre si c'est une chaîne
    value = Number(value);
    // S'assurer que c'est un nombre valide
    if (isNaN(value)) {
        value = 0;
    }
    return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, " ") + " $";
}

// Mise à jour de l'historique des transactions
function updateTransactionHistory() {
    const historyContainer=document.querySelector('.history');
    historyContainer.innerHTML='';

    transactionHistory.forEach(transaction=> {
            const transactionElem=document.createElement('div');
            transactionElem.className='container-transaction';

            // Type de transaction
            const typeElem=document.createElement('div');
            typeElem.className='type';
            typeElem.textContent=transaction.type;

            // Date de la transaction
            const dateElem=document.createElement('div');
            dateElem.className='date';
            dateElem.textContent=transaction.date;

            // Statut de la transaction
            const statusElem=document.createElement('div');
            statusElem.className='confirmed';
            statusElem.textContent=transaction.status || 'La transaction a été confirmée';

            // Montant de la transaction
            const amountElem=document.createElement('div');
            amountElem.className='amount';
            const amount=transaction.amount;
            const isNegative=amount < 0;

            // Formater le montant avec + ou - et la couleur appropriée
            amountElem.textContent = isNegative 
                ? `- ${formatMoney(Math.abs(amount))}` 
                : `+ ${formatMoney(amount)}`;
            amountElem.style.color = isNegative ? '#ff5555' : '#55ff7f';

            // Ajout des éléments à la transaction
            transactionElem.appendChild(typeElem);
            transactionElem.appendChild(dateElem);
            transactionElem.appendChild(statusElem);
            transactionElem.appendChild(amountElem);

            // Ajout de la transaction à l'historique
            historyContainer.appendChild(transactionElem);
        }

    );
}

// Dépôt d'argent
function depositMoney(amount) {
    // Désactiver le bouton pendant la transaction
    const depositButton = document.querySelector('.deposit-input button');
    depositButton.disabled = true;
    depositButton.textContent = "En cours...";

    fetch('https://mBanking/deposit', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            amount: amount
        })
    })
    .then(resp => resp.json())
    .then(data => {
        // Réactiver le bouton
        depositButton.disabled = false;
        depositButton.textContent = "Déposer";

        if (data.success) {
            // Ne pas mettre à jour les données localement
            // Attendre plutôt que le serveur envoie les données à jour
            // showNotification("Dépôt effectué avec succès!");
        } else {
            // showNotification("Le dépôt a échoué: " + (data.reason || "Erreur inconnue"));
        }
    })
    .catch(error => {
        // Réactiver le bouton en cas d'erreur
        depositButton.disabled = false;
        depositButton.textContent = "Déposer";
        // console.error('Erreur lors du dépôt:', error);
        // showNotification("Erreur de communication avec le serveur");
    });
}

// Retrait d'argent
function withdrawMoney(amount) {
    if (amount > playerMoney) {
        fetch(`https://${GetParentResourceName()}/showNotification`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({
              message: "Vous n'avez pas assez d'argent en banque."
            })
          });          
        return;
    }

    // Désactiver le bouton pendant la transaction
    const withdrawButton = document.querySelector('.withdraw-input button');
    withdrawButton.disabled = true;
    withdrawButton.textContent = "En cours...";

    fetch('https://mBanking/withdraw', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            amount: amount
        })
    })
    .then(resp => resp.json())
    .then(data => {
        // Réactiver le bouton
        withdrawButton.disabled = false;
        withdrawButton.textContent = "Retirer";

        if (data.success) {
            // Ne pas mettre à jour les données localement
            // Attendre plutôt que le serveur envoie les données à jour
            // showNotification("Retrait effectué avec succès!");
        } else {
            // showNotification("Le retrait a échoué: " + (data.reason || "Erreur inconnue"));
        }
    })
    .catch(error => {
        // Réactiver le bouton en cas d'erreur
        withdrawButton.disabled = false;
        withdrawButton.textContent = "Retirer";
        // console.error('Erreur lors du retrait:', error);
        // showNotification("Erreur de communication avec le serveur");
    });
}

// Transfert d'argent
function transferMoney(amount, targetId) {
    if (amount > playerMoney) {
        fetch(`https://${GetParentResourceName()}/showNotification`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({
              message: "Vous n'avez pas assez d'argent en banque."
            })
          });  
        return;
    }

    // Désactiver le bouton pendant la transaction
    const transferButton = document.querySelector('.transfer-input button');
    transferButton.disabled = true;
    transferButton.textContent = "En cours...";

    fetch('https://mBanking/transfer', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            amount: amount,
            target: targetId
        })
    })
    .then(resp => resp.json())
    .then(data => {
        // Réactiver le bouton
        transferButton.disabled = false;
        transferButton.textContent = "Transférer";

        if (data.success) {
            // Ne pas mettre à jour les données localement
            // Attendre plutôt que le serveur envoie les données à jour
            // showNotification("Transfert effectué avec succès!");
        } else {
            // showNotification("Le transfert a échoué: " + (data.reason || "Erreur inconnue"));
        }
    })
    .catch(error => {
        // Réactiver le bouton en cas d'erreur
        transferButton.disabled = false;
        transferButton.textContent = "Transférer";
        // console.error('Erreur lors du transfert:', error);
        // showNotification("Erreur de communication avec le serveur");
    });
}

// Réclamation du bonus hebdomadaire
function claimWeeklyBonus() {
    fetch('https://mBanking/claimBonus', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    })
    .then(resp => resp.json())
    .then(data => {
        if (data.success) {
            // S'assurer que data.amount est défini
            const bonusAmount = data.amount || 0;
            
            playerMoney += bonusAmount;
            lastBonusClaim = Date.now();

            // Ajout de la transaction à l'historique
            const transaction = {
                type: 'Bonus',
                date: getCurrentDate(),
                status: 'Bonus Hebdomadaire',
                amount: bonusAmount
            };

            transactionHistory.unshift(transaction);

            // Mise à jour de l'interface
            document.getElementById('info-wallet-value').textContent = formatMoney(playerMoney);
            updateTransactionHistory();
            
            // Mettre à jour l'état du bouton de bonus
            checkWeeklyBonusAvailability();
        }
    })
    .catch(error => {
        // console.error('Erreur lors de la réclamation du bonus:', error);
    });
}

// Obtenir la date actuelle formatée
function getCurrentDate() {
    const now = new Date();
    const day = now.getDate().toString().padStart(2, '0');
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    const year = now.getFullYear();
    return `${day}/${month}/${year}`;
}

// Fermeture de l'interface
function closeUI() {
    fetch('https://mBanking/closeUI', {

            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }

            ,
            body: JSON.stringify( {}

            )
        }

    );
}


// Réception des messages depuis le client Lua
window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.type) {
        case 'showUI':
            document.querySelector('.container').style.display = 'flex';
            fetchInitialData();
            break;

        case 'hideUI':
            document.querySelector('.container').style.display = 'none';
            break;

        case 'updateData':
            // console.log("Mise à jour des données:", data);
            updateUIWithData(data);
            break;

        case 'refreshData':
            // console.log("Rafraîchissement des données forcé:", data);
            // console.log("Mois actuel:", data.currentMonth);
            
            if (data.forceUpdate) {
                if (data.currentMonth !== undefined) {
                    const monthIndex = parseInt(data.currentMonth);
                    currentMonth = (monthIndex >= 1 && monthIndex <= 12) ? monthIndex - 1 : 0;
                }
                
                fetchInitialData();
            }
            break;
    }
});

// Vérifier la disponibilité du bonus hebdomadaire
function checkWeeklyBonusAvailability() {
    const bonusButton = document.querySelector('.weekly-bonus button');
    const now = Date.now();
    const oneWeekInMs = 7 * 24 * 60 * 60 * 1000; // 7 jours en millisecondes
    
    if (lastBonusClaim > 0 && (now - lastBonusClaim < oneWeekInMs)) {
        // Bonus déjà réclamé et en cooldown
        bonusButton.disabled = true;
        bonusButton.style.opacity = "0.5";
        bonusButton.style.cursor = "not-allowed";
        bonusButton.textContent = "Indisponible";
    } else {
        // Bonus disponible
        bonusButton.disabled = false;
        bonusButton.style.opacity = "1";
        bonusButton.style.cursor = "pointer";
        bonusButton.textContent = "Réclamer";
    }
}

// // Fonction pour afficher une notification
function showNotification(message) {
    // Créer un élément de notification
    const notification=document.createElement('div');
    notification.className='notification';
    notification.textContent=message;

    // Ajouter la notification au document
    document.body.appendChild(notification);

    // Supprimer la notification après 3 secondes
    setTimeout(()=> {
            notification.classList.add('fade-out');

            setTimeout(()=> {
                    document.body.removeChild(notification);
                }

                , 500);
        }

        , 3000);
}