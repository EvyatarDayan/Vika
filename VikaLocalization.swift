//
//  VikaLocalization.swift
//  Vika
//

import Foundation

/// Central string table for in-app language switching (5 languages, English fallback).
enum VikaL10n {
    enum Key: String {
        case languageModalTitle
        case appTagline

        case onboardingPrev
        case onboardingNext
        case onboardingGetStarted

        case onboardingWelcomeTitle
        case onboardingWelcomeSubtitle
        case onboardingWelcomeBody

        case onboardingClientTitle
        case onboardingClientSubtitle
        case onboardingClientBody

        case onboardingFolderTitle
        case onboardingFolderSubtitle
        case onboardingFolderBody

        case onboardingDoneTitle
        case onboardingDoneSubtitle
        case onboardingDoneBody

        case profileTitle
        case profileLogout
        case profileClose
        case profileUpdate
        case profilePhotoSection
        case chooseProfilePhotoTitle
        case chooseFromAvatarOption
        case chooseFromLibraryOption
        case chooseAvatarTitle
        case profileGalleryTitle
        case profileGalleryAdd
        case showPhoneNumberToggle
        case showAddressToggle
        case isFolderToggle
        case fieldChargingFee

        case fieldFirstName
        case fieldLastName
        case fieldFullName
        case fieldEmail
        case fieldPhone
        case fieldAddress

        case placeholderFirstName
        case placeholderLastName
        case placeholderEmail
        case placeholderPhone
        case placeholderChargingFee
        case placeholderAddress

        case addressPrivacy

        case alertOK
        case profileAlertTitle
        case profileErrorFillRequired
        case profileUpdatedSuccess

        case loginAlertTitle
        case accountAlertTitle
        case loginSignIn
        case loginSignUp
        case loginFullName
        case loginEnterFullName
        case loginEmail
        case loginEnterEmail
        case loginPassword
        case loginEnterPassword
        case loginConfirmPassword
        case loginConfirmYourPassword
        case loginForgotPassword
        case loginDontHaveAccount
        case loginAlreadyHaveAccount
        case loginPleaseEnterEmailAndPassword
        case loginPleaseFillAllFields
        case loginPasswordsDoNotMatch
        case loginIncorrectCredentials
        case loginNoAccountFound
        case loginInvalidEmail
        case loginEmailInUse
        case loginChooseStrongerPassword
        case loginCreateFailed
        case loginEnterEmailFirst
        case loginResetEmailSent

        case findTitleProfile
        case findTitleSettings
        case findTitleFolders
        case findTitleClients
        case findAudienceLabel
        case findAudienceFolders
        case findAudienceClients
        case findLoadingUsers
        case findNoResults
        case findTryChangeFilter
        case findFilterAll
        case findFilterFavorites
        case findFilterNearby
        case findNoFavorites
        case findMessage
        case findMap
        case findList
        case findMapLoading
        case findMapNoAddresses
        case findDistanceCalculating
        case findDistanceNoAddress
        case findDistanceUnavailable
        case profileFavoriteFolder
        case profileFavoriteAddedToast
        case errorTitle
        case statusNew
        case statusActive
        case tabFind
        case tabHistory
        case tabProfile
        case tabSettings
        case roleFolderUpper
        case roleClientUpper
        case roleUserUpper
        case roleFolder
        case roleClient
        case roleUser

        case settingsTitle
        case settingsAuthentication
        case settingsPreferences
        case settingsSupport
        case settingsDataManagement
        case settingsLanguage
        case settingsLanguageSubtitle
        case settingsCurrency
        case settingsCurrencySubtitle
        case settingsCurrencyTapToChoose
        case selectCurrencyTitle
        case selectCurrencySearchPlaceholder
        case selectCurrencyCancel
        case settingsDarkMode
        case settingsDarkModeSubtitle
        case settingsHelpSupport
        case settingsHelpSupportSubtitle
        case settingsTermsPrivacy
        case settingsTermsPrivacySubtitle
        case settingsAbout
        case settingsAboutSubtitle
        case settingsExportData
        case settingsExportDataSubtitle
        case settingsClearAllData
        case settingsClearAllDataSubtitle
        case settingsExportComingSoon
        case settingsExportAlertTitle
        case settingsClearAlertTitle
        case settingsClearAlertMessage
        case settingsCancel
        case settingsClearAll
        case settingsDone
        case settingsLogout

        case detailsNotProvided
        case detailsPhoneHiddenByUser
        case detailsAddressHiddenByUser
        case findPhoneHiddenShort

        case livePayTitle
        case livePayReadyToStart
        case livePaySessionRunning
        case livePaySessionEnded
        case livePayDuration
        case livePayPay
        case livePaySelectFolderToStart
        case livePayStopConfirmTitle
        case livePayStopConfirmMessage
        case livePayContinue
        case livePayYesStop
        case livePayFavoriteFoldersTitle
        case livePayNoFavoriteFolders
        case livePayHourlyRate
        case livePayOtherPays
        case livePayFolderToolbar
        case livePayFindOtherFolders

        case historyTitle
        case historyAll
        case historyExport
        case historyEmpty
        case historyPaid
        case historyPending
        case historyPdfTitle
        case historyPdfTotalRecords
        case historyColumnName
        case historyColumnDate
        case historyColumnDuration
        case historyColumnTotal
        case historyColumnStatus
        case historyDurationHourOne
        case historyDurationHours
        case historyDurationMinuteOne
        case historyDurationMinutes
        case historyDurationAnd
        case historyDurationZero
        case historyDetailTitle
        case historyMarkPaid

        case messagesTitle
        case messagesLoading
        case messagesEmpty
        case messagesEmptyDescription
        case messagesStartBrowsing
        case messagesSampleCaption
        case messagesSampleFolderName
        case messagesSampleBody
        case messagesErrorNoMessage
        case messagesLoadingConversation
        case messagesNoMessagesFound
        case messagesTypeSomething
        case messagesSend
        case matchesPreMessageButton
        case messagesPreviewPhoto
        case messagesPreviewVoice
        case messagesPreviewVoiceDuration
        case messagesVoiceRecording
        case messagesVoiceReady
        case messagesYou
        case messagesOtherUser
        case messagesImageSaved
        case messagesImageSavedSuccess
        case messagesImageSavedFailed
        case commonClose
        case commonSave
        case commonDelete
        case tabMessages
        case messagesMicrophoneAlertTitle
        case messagesMicrophoneAlertMessage
        case messagesNotificationTitle
        case messagesNotificationFrom
        case messagesNotificationOpen
        case messagesNotificationLater
        case messagesNewThreadStarter
        case messagesStartThreadFailed
        case profileNoPhotos
    }

    private static let table: [String: [Key: String]] = [
        "en": [
            .languageModalTitle: "Language",
            .appTagline: "A safe space for meaningful connections",

            .onboardingPrev: "Previous",
            .onboardingNext: "Next",
            .onboardingGetStarted: "Get started",

            .onboardingWelcomeTitle: "Welcome to Vika",
            .onboardingWelcomeSubtitle: "Laundry help, made simple",
            .onboardingWelcomeBody: "Vika connects busy families who need folding help with local Folders who can take a pile off your hands.",

            .onboardingClientTitle: "I’m a Client",
            .onboardingClientSubtitle: "Need help with the pile?",
            .onboardingClientBody: "Post your need, browse trusted Folders nearby, and get your laundry mountain turned into a neat stack.",

            .onboardingFolderTitle: "I’m a Folder",
            .onboardingFolderSubtitle: "Earn by folding",
            .onboardingFolderBody: "Offer folding help on your schedule. Connect with Clients who value your time and care.",

            .onboardingDoneTitle: "You’re set",
            .onboardingDoneSubtitle: "Let’s get started",
            .onboardingDoneBody: "Create an account as a Folder or Client, complete your profile, and start matching.",

            .profileTitle: "Profile",
            .profileLogout: "Logout",
            .profileClose: "Close",
            .profileUpdate: "Save",
            .profilePhotoSection: "Profile Photo",
            .chooseProfilePhotoTitle: "Choose profile photo",
            .chooseFromAvatarOption: "Choose from Avatar",
            .chooseFromLibraryOption: "Choose from Library",
            .chooseAvatarTitle: "Choose Avatar",
            .profileGalleryTitle: "My Photos",
            .profileGalleryAdd: "Add",
            .showPhoneNumberToggle: "Display my phone number",
            .showAddressToggle: "Display my address",
            .isFolderToggle: "I'm a folder",

            .fieldFirstName: "First name",
            .fieldLastName: "Last name",
            .fieldFullName: "Full name",
            .fieldEmail: "Email",
            .fieldPhone: "Phone number",
            .fieldChargingFee: "Charging fee",
            .fieldAddress: "Address",

            .placeholderFirstName: "First name",
            .placeholderLastName: "Last name",
            .placeholderEmail: "Email address",
            .placeholderPhone: "Phone number",
            .placeholderChargingFee: "Charging fee",
            .placeholderAddress: "Address",

            .addressPrivacy: "Your address will not be shared",

            .alertOK: "OK",
            .profileAlertTitle: "Profile",
            .profileErrorFillRequired: "Please fill first name, last name and phone number.",
            .profileUpdatedSuccess: "Profile updated.",

            .loginAlertTitle: "Login",
            .accountAlertTitle: "Account",
            .loginSignIn: "Sign In",
            .loginSignUp: "Sign Up",
            .loginFullName: "Full Name",
            .loginEnterFullName: "Enter your full name",
            .loginEmail: "Email",
            .loginEnterEmail: "Enter your email",
            .loginPassword: "Password",
            .loginEnterPassword: "Enter your password",
            .loginConfirmPassword: "Confirm Password",
            .loginConfirmYourPassword: "Confirm your password",
            .loginForgotPassword: "Forgot Password?",
            .loginDontHaveAccount: "Don't have an account?",
            .loginAlreadyHaveAccount: "Already have an account?",
            .loginPleaseEnterEmailAndPassword: "Please enter your email and password.",
            .loginPleaseFillAllFields: "Please fill out all fields.",
            .loginPasswordsDoNotMatch: "Passwords do not match.",
            .loginIncorrectCredentials: "Email or password is incorrect.",
            .loginNoAccountFound: "No account found for this email.",
            .loginInvalidEmail: "Please enter a valid email address.",
            .loginEmailInUse: "This email is already in use.",
            .loginChooseStrongerPassword: "Please choose a stronger password.",
            .loginCreateFailed: "Could not create account. Please try again.",
            .loginEnterEmailFirst: "Enter your email first, then tap Forgot Password.",
            .loginResetEmailSent: "Reset email sent.",

            .findTitleProfile: "Profile",
            .findTitleSettings: "Settings",
            .findTitleFolders: "Find Folders",
            .findTitleClients: "Find Clients",
            .findAudienceLabel: "Audience",
            .findAudienceFolders: "Folders",
            .findAudienceClients: "Clients",
            .findLoadingUsers: "Loading users...",
            .findNoResults: "No results",
            .findTryChangeFilter: "Try changing your search or filter.",
            .findFilterAll: "All",
            .findFilterFavorites: "Favorites",
            .findFilterNearby: "Nearby",
            .findNoFavorites: "No favorite folders yet. Tap the star on a profile to add one.",
            .findMessage: "Message",
            .findMap: "Map",
            .findList: "List",
            .findMapLoading: "Loading map…",
            .findMapNoAddresses: "No addresses to show. Profiles need an address to appear on the map.",
            .findDistanceCalculating: "Updating distance",
            .findDistanceNoAddress: "No address",
            .findDistanceUnavailable: "Distance unavailable",
            .profileFavoriteFolder: "Favorite folder",
            .profileFavoriteAddedToast: "%@ added to your favorites",
            .errorTitle: "Error",
            .statusNew: "New",
            .statusActive: "Active",
            .tabFind: "Find",
            .tabHistory: "History",
            .tabProfile: "Profile",
            .tabSettings: "Settings",
            .roleFolderUpper: "FOLDER",
            .roleClientUpper: "CLIENT",
            .roleUserUpper: "USER",
            .roleFolder: "Folder",
            .roleClient: "Client",
            .roleUser: "User",

            .settingsTitle: "Settings",
            .settingsAuthentication: "Authentication",
            .settingsPreferences: "Preferences",
            .settingsSupport: "Support",
            .settingsDataManagement: "Data Management",
            .settingsLanguage: "Language",
            .settingsLanguageSubtitle: "Choose your app language",
            .settingsCurrency: "Currency",
            .settingsCurrencySubtitle: "Automatically selected",
            .settingsCurrencyTapToChoose: "Tap to choose currency",
            .selectCurrencyTitle: "Select Currency",
            .selectCurrencySearchPlaceholder: "Search Currency",
            .selectCurrencyCancel: "Cancel",
            .settingsDarkMode: "Dark mode",
            .settingsDarkModeSubtitle: "Use a darker appearance",
            .settingsHelpSupport: "Help & Support",
            .settingsHelpSupportSubtitle: "Get help and contact us",
            .settingsTermsPrivacy: "Terms & Privacy",
            .settingsTermsPrivacySubtitle: "Review policies and terms",
            .settingsAbout: "About",
            .settingsAboutSubtitle: "Version and app details",
            .settingsExportData: "Export Data",
            .settingsExportDataSubtitle: "Export your data to file",
            .settingsClearAllData: "Clear All Data",
            .settingsClearAllDataSubtitle: "This cannot be undone",
            .settingsExportComingSoon: "Export is coming soon.",
            .settingsExportAlertTitle: "Export Data",
            .settingsClearAlertTitle: "Clear All Data",
            .settingsClearAlertMessage: "This will permanently delete your local app data. This action cannot be undone.",
            .settingsCancel: "Cancel",
            .settingsClearAll: "Clear All",
            .settingsDone: "Done",
            .settingsLogout: "Logout",

            .detailsNotProvided: "Not provided",
            .detailsPhoneHiddenByUser: "%@ phone number hidden for privacy",
            .detailsAddressHiddenByUser: "%@ address hidden for privacy",
            .findPhoneHiddenShort: "Phone hidden",

            .livePayTitle: "Live pay",
            .livePayReadyToStart: "Ready to start",
            .livePaySessionRunning: "Session is running",
            .livePaySessionEnded: "Session ended",
            .livePayDuration: "Duration",
            .livePayPay: "Pay",
            .livePaySelectFolderToStart: "Select a folder to start",
            .livePayStopConfirmTitle: "Stop session?",
            .livePayStopConfirmMessage: "End the timer and calculate pay.",
            .livePayContinue: "Continue",
            .livePayYesStop: "Stop",
            .livePayFavoriteFoldersTitle: "Favorite folders",
            .livePayNoFavoriteFolders: "No favorite folders yet. Add some from Find.",
            .livePayHourlyRate: "Hourly rate",
            .livePayOtherPays: "Other pays",
            .livePayFolderToolbar: "Folder",
            .livePayFindOtherFolders: "Find other folders",

            .historyTitle: "History",
            .historyAll: "All",
            .historyExport: "Export",
            .historyEmpty: "No payment history yet.",
            .historyPaid: "Paid",
            .historyPending: "Pending",
            .historyPdfTitle: "Payment history",
            .historyPdfTotalRecords: "Total records: %d",
            .historyColumnName: "Name",
            .historyColumnDate: "Date",
            .historyColumnDuration: "Duration",
            .historyColumnTotal: "Total",
            .historyColumnStatus: "Status",
            .historyDurationHourOne: "1 hour",
            .historyDurationHours: "%d hours",
            .historyDurationMinuteOne: "1 minute",
            .historyDurationMinutes: "%d minutes",
            .historyDurationAnd: "and",
            .historyDurationZero: "0 minutes",
            .historyDetailTitle: "Payment",
            .historyMarkPaid: "Mark as paid",

            .messagesTitle: "Messages",
            .messagesLoading: "Loading…",
            .messagesEmpty: "No messages yet",
            .messagesEmptyDescription: "When you connect with folders or clients, your conversations will appear here.",
            .messagesStartBrowsing: "Browse folders",
            .messagesSampleCaption: "Preview",
            .messagesSampleFolderName: "Sample folder",
            .messagesSampleBody: "Sounds good — I can pick up on Saturday.",
            .messagesErrorNoMessage: "Could not open this conversation.",
            .messagesLoadingConversation: "Loading conversation…",
            .messagesNoMessagesFound: "No messages in this thread.",
            .messagesTypeSomething: "Message",
            .messagesSend: "Send",
            .matchesPreMessageButton: "Quick replies",
            .messagesPreviewPhoto: "Photo",
            .messagesPreviewVoice: "Voice message",
            .messagesPreviewVoiceDuration: "%@",
            .messagesVoiceRecording: "Recording…",
            .messagesVoiceReady: "Voice ready",
            .messagesYou: "You",
            .messagesOtherUser: "User",
            .messagesImageSaved: "Saved",
            .messagesImageSavedSuccess: "Image saved to Photos.",
            .messagesImageSavedFailed: "Could not save the image.",
            .commonClose: "Close",
            .commonSave: "Save",
            .commonDelete: "Delete",
            .tabMessages: "Messages",
            .messagesMicrophoneAlertTitle: "Microphone",
            .messagesMicrophoneAlertMessage: "Enable microphone access in Settings to send voice messages.",
            .messagesNotificationTitle: "New message",
            .messagesNotificationFrom: "from %@",
            .messagesNotificationOpen: "Open message",
            .messagesNotificationLater: "Later",
            .messagesNewThreadStarter: "Hi — I’d like to connect about laundry help.",
            .messagesStartThreadFailed: "Couldn’t start the conversation. Please try again.",
            .profileNoPhotos: "No photos",
        ],
        "fr": [
            .languageModalTitle: "Langue",

            .onboardingPrev: "Précédent",
            .onboardingNext: "Suivant",
            .onboardingGetStarted: "Commencer",

            .onboardingWelcomeTitle: "Bienvenue sur Vika",
            .onboardingWelcomeSubtitle: "Le linge, sans stress",
            .onboardingWelcomeBody: "Vika met en relation les familles débordées et des plieurs près de chez vous pour soulager la montagne de linge.",

            .onboardingClientTitle: "Je suis Client",
            .onboardingClientSubtitle: "Besoin d’un coup de main ?",
            .onboardingClientBody: "Publiez votre besoin, parcourez des plieurs de confiance à proximité et transformez la pile en piles bien rangées.",

            .onboardingFolderTitle: "Je suis plieur / plieuse",
            .onboardingFolderSubtitle: "Gagnez en pliant",
            .onboardingFolderBody: "Proposez votre aide selon vos disponibilités. Rencontrez des Clients qui apprécient votre temps et votre soin.",

            .onboardingDoneTitle: "C’est parti",
            .onboardingDoneSubtitle: "On commence",
            .onboardingDoneBody: "Créez un compte en tant que plieur ou Client, complétez votre profil et commencez à matcher.",

            .profileTitle: "Profil",
            .profileLogout: "Déconnexion",
            .profileClose: "Fermer",
            .profileUpdate: "Mettre à jour",
            .profilePhotoSection: "Photo de profil",
            .chooseProfilePhotoTitle: "Choisir la photo de profil",
            .chooseFromAvatarOption: "Choisir parmi les avatars",
            .chooseFromLibraryOption: "Choisir depuis la bibliothèque",
            .chooseAvatarTitle: "Choisir un avatar",
            .profileGalleryTitle: "Mes photos",
            .profileGalleryAdd: "Ajouter",
            .showPhoneNumberToggle: "Afficher mon numero de telephone",
            .showAddressToggle: "Afficher mon adresse",
            .isFolderToggle: "Je suis plieur / plieuse",

            .fieldFirstName: "Prénom",
            .fieldLastName: "Nom",
            .fieldFullName: "Nom complet",
            .fieldEmail: "E-mail",
            .fieldPhone: "Téléphone",
            .fieldChargingFee: "Tarif",
            .fieldAddress: "Adresse",

            .placeholderFirstName: "Prénom",
            .placeholderLastName: "Nom",
            .placeholderEmail: "Adresse e-mail",
            .placeholderPhone: "Numéro de téléphone",
            .placeholderChargingFee: "Tarif",
            .placeholderAddress: "Adresse",

            .addressPrivacy: "Votre adresse ne sera pas partagée",

            .alertOK: "OK",
            .profileAlertTitle: "Profil",
            .profileErrorFillRequired: "Veuillez renseigner le prénom, le nom et le téléphone.",
            .profileUpdatedSuccess: "Profil mis à jour.",

            .appTagline: "Un espace sûr pour des liens authentiques",
            .loginAlertTitle: "Connexion",
            .accountAlertTitle: "Compte",
            .loginSignIn: "Se connecter",
            .loginSignUp: "S’inscrire",
            .loginFullName: "Nom complet",
            .loginEnterFullName: "Entrez votre nom complet",
            .loginEmail: "E-mail",
            .loginEnterEmail: "Entrez votre e-mail",
            .loginPassword: "Mot de passe",
            .loginEnterPassword: "Entrez votre mot de passe",
            .loginConfirmPassword: "Confirmer le mot de passe",
            .loginConfirmYourPassword: "Confirmez votre mot de passe",
            .loginForgotPassword: "Mot de passe oublié ?",
            .loginDontHaveAccount: "Vous n’avez pas de compte ?",
            .loginAlreadyHaveAccount: "Vous avez déjà un compte ?",
            .loginPleaseEnterEmailAndPassword: "Veuillez saisir votre e-mail et votre mot de passe.",
            .loginPleaseFillAllFields: "Veuillez remplir tous les champs.",
            .loginPasswordsDoNotMatch: "Les mots de passe ne correspondent pas.",
            .loginIncorrectCredentials: "E-mail ou mot de passe incorrect.",
            .loginNoAccountFound: "Aucun compte trouvé pour cet e-mail.",
            .loginInvalidEmail: "Veuillez saisir une adresse e-mail valide.",
            .loginEmailInUse: "Cet e-mail est déjà utilisé.",
            .loginChooseStrongerPassword: "Veuillez choisir un mot de passe plus robuste.",
            .loginCreateFailed: "Impossible de créer le compte. Veuillez réessayer.",
            .loginEnterEmailFirst: "Saisissez d’abord votre e-mail, puis appuyez sur Mot de passe oublié.",
            .loginResetEmailSent: "E-mail de réinitialisation envoyé.",

            .findTitleProfile: "Profil",
            .findTitleSettings: "Réglages",
            .findTitleFolders: "Trouver des Folders",
            .findTitleClients: "Trouver des Clients",
            .findAudienceLabel: "Audience",
            .findAudienceFolders: "Folders",
            .findAudienceClients: "Clients",
            .findLoadingUsers: "Chargement des utilisateurs...",
            .findNoResults: "Aucun résultat",
            .findTryChangeFilter: "Essayez de modifier votre recherche ou le filtre.",
            .findFilterAll: "Tous",
            .findFilterFavorites: "Favoris",
            .findFilterNearby: "À proximité",
            .findNoFavorites: "Aucun dossier favori. Touchez l’étoile sur un profil pour en ajouter.",
            .findMessage: "Message",
            .findMap: "Carte",
            .findList: "Liste",
            .findMapLoading: "Chargement de la carte…",
            .findMapNoAddresses: "Aucune adresse à afficher. Les profils doivent avoir une adresse pour apparaître sur la carte.",
            .findDistanceCalculating: "Mise à jour de la distance",
            .findDistanceNoAddress: "Pas d’adresse",
            .findDistanceUnavailable: "Distance indisponible",
            .profileFavoriteFolder: "Dossier favori",
            .profileFavoriteAddedToast: "%@ a été ajouté à vos favoris",
            .errorTitle: "Erreur",
            .statusNew: "Nouveau",
            .statusActive: "Actif",
            .tabFind: "Trouver",
            .tabHistory: "Historique",
            .tabProfile: "Profil",
            .tabSettings: "Réglages",
            .roleFolderUpper: "FOLDER",
            .roleClientUpper: "CLIENT",
            .roleUserUpper: "UTILISATEUR",
            .roleFolder: "Folder",
            .roleClient: "Client",
            .roleUser: "Utilisateur",

            .settingsTitle: "Réglages",
            .settingsAuthentication: "Authentification",
            .settingsPreferences: "Préférences",
            .settingsSupport: "Assistance",
            .settingsDataManagement: "Gestion des données",
            .settingsLanguage: "Langue",
            .settingsLanguageSubtitle: "Choisissez la langue de l’application",
            .settingsCurrency: "Devise",
            .settingsCurrencySubtitle: "Sélection automatique",
            .settingsCurrencyTapToChoose: "Appuyez pour choisir la devise",
            .selectCurrencyTitle: "Choisir la devise",
            .selectCurrencySearchPlaceholder: "Rechercher une devise",
            .selectCurrencyCancel: "Annuler",
            .settingsDarkMode: "Mode sombre",
            .settingsDarkModeSubtitle: "Utiliser une apparence plus sombre",
            .settingsHelpSupport: "Aide et assistance",
            .settingsHelpSupportSubtitle: "Obtenez de l’aide et contactez-nous",
            .settingsTermsPrivacy: "Conditions et confidentialité",
            .settingsTermsPrivacySubtitle: "Consultez les politiques et conditions",
            .settingsAbout: "À propos",
            .settingsAboutSubtitle: "Version et informations de l’application",
            .settingsExportData: "Exporter les données",
            .settingsExportDataSubtitle: "Exporter vos données vers un fichier",
            .settingsClearAllData: "Effacer toutes les données",
            .settingsClearAllDataSubtitle: "Cette action est irréversible",
            .settingsExportComingSoon: "L’export sera disponible bientôt.",
            .settingsExportAlertTitle: "Exporter les données",
            .settingsClearAlertTitle: "Effacer toutes les données",
            .settingsClearAlertMessage: "Cela supprimera définitivement vos données locales. Cette action est irréversible.",
            .settingsCancel: "Annuler",
            .settingsClearAll: "Tout effacer",
            .settingsDone: "Terminé",
            .settingsLogout: "Déconnexion",

            .detailsNotProvided: "Non renseigné",
            .detailsPhoneHiddenByUser: "%@ numéro de téléphone masqué pour confidentialité",
            .detailsAddressHiddenByUser: "%@ adresse masquée pour confidentialité",
            .findPhoneHiddenShort: "Numéro masqué",

            .livePayTitle: "Séance en direct",
            .livePayReadyToStart: "Prêt à démarrer",
            .livePaySessionRunning: "Séance en cours",
            .livePaySessionEnded: "Séance terminée",
            .livePayDuration: "Durée",
            .livePayPay: "Payer",
            .livePaySelectFolderToStart: "Choisissez un dossier pour commencer",
            .livePayStopConfirmTitle: "Arrêter la séance ?",
            .livePayStopConfirmMessage: "Arrêter le minuteur et calculer le paiement.",
            .livePayContinue: "Continuer",
            .livePayYesStop: "Arrêter",
            .livePayFavoriteFoldersTitle: "Dossiers favoris",
            .livePayNoFavoriteFolders: "Aucun dossier favori. Ajoutez-en depuis Rechercher.",
            .livePayHourlyRate: "Tarif horaire",
            .livePayOtherPays: "Autres montants",
            .livePayFolderToolbar: "Dossier",
            .livePayFindOtherFolders: "Trouver d’autres dossiers",

            .historyTitle: "Historique",
            .historyAll: "Tous",
            .historyExport: "Exporter",
            .historyEmpty: "Aucun historique de paiement.",
            .historyPaid: "Payé",
            .historyPending: "En attente",
            .historyPdfTitle: "Historique des paiements",
            .historyPdfTotalRecords: "Nombre d’enregistrements : %d",
            .historyColumnName: "Nom",
            .historyColumnDate: "Date",
            .historyColumnDuration: "Durée",
            .historyColumnTotal: "Total",
            .historyColumnStatus: "Statut",
            .historyDurationHourOne: "1 heure",
            .historyDurationHours: "%d heures",
            .historyDurationMinuteOne: "1 minute",
            .historyDurationMinutes: "%d minutes",
            .historyDurationAnd: "et",
            .historyDurationZero: "0 minute",
            .historyDetailTitle: "Paiement",
            .historyMarkPaid: "Marquer comme payé",

            .messagesTitle: "Messages",
            .messagesLoading: "Chargement…",
            .messagesEmpty: "Aucun message",
            .messagesEmptyDescription: "Lorsque vous échangez avec des dossiers ou des clients, vos conversations apparaîtront ici.",
            .messagesStartBrowsing: "Parcourir les dossiers",
            .messagesSampleCaption: "Aperçu",
            .messagesSampleFolderName: "Dossier d’exemple",
            .messagesSampleBody: "Parfait — je peux passer samedi.",
            .messagesErrorNoMessage: "Impossible d’ouvrir cette conversation.",
            .messagesLoadingConversation: "Chargement de la conversation…",
            .messagesNoMessagesFound: "Aucun message dans ce fil.",
            .messagesTypeSomething: "Message",
            .messagesSend: "Envoyer",
            .matchesPreMessageButton: "Réponses rapides",
            .messagesPreviewPhoto: "Photo",
            .messagesPreviewVoice: "Message vocal",
            .messagesPreviewVoiceDuration: "%@",
            .messagesVoiceRecording: "Enregistrement…",
            .messagesVoiceReady: "Message vocal prêt",
            .messagesYou: "Vous",
            .messagesOtherUser: "Utilisateur",
            .messagesImageSaved: "Enregistré",
            .messagesImageSavedSuccess: "Image enregistrée dans Photos.",
            .messagesImageSavedFailed: "Impossible d’enregistrer l’image.",
            .commonClose: "Fermer",
            .commonSave: "Enregistrer",
            .commonDelete: "Supprimer",
            .tabMessages: "Messages",
            .messagesMicrophoneAlertTitle: "Microphone",
            .messagesMicrophoneAlertMessage: "Activez le microphone dans Réglages pour envoyer des messages vocaux.",
            .messagesNotificationTitle: "Nouveau message",
            .messagesNotificationFrom: "de %@",
            .messagesNotificationOpen: "Ouvrir le message",
            .messagesNotificationLater: "Plus tard",
            .messagesNewThreadStarter: "Bonjour — je souhaite échanger au sujet du service de blanchisserie.",
            .messagesStartThreadFailed: "Impossible de démarrer la conversation. Réessayez.",
            .profileNoPhotos: "Aucune photo",
        ],
        "de": [
            .languageModalTitle: "Sprache",

            .onboardingPrev: "Zurück",
            .onboardingNext: "Weiter",
            .onboardingGetStarted: "Los geht’s",

            .onboardingWelcomeTitle: "Willkommen bei Vika",
            .onboardingWelcomeSubtitle: "Wäschehilfe, ganz einfach",
            .onboardingWelcomeBody: "Vika bringt Familien, die beim Falten Hilfe brauchen, mit Foldern in Ihrer Nähe zusammen.",

            .onboardingClientTitle: "Ich bin Kunde",
            .onboardingClientSubtitle: "Hilfe bei der Wäsche?",
            .onboardingClientBody: "Teilen Sie Ihren Bedarf, finden Sie vertrauenswürdige Folder in der Nähe und verwandeln Sie den Stapel in Ordnung.",

            .onboardingFolderTitle: "Ich bin Folder",
            .onboardingFolderSubtitle: "Verdienen beim Falten",
            .onboardingFolderBody: "Bieten Sie Hilfe zu Ihren Zeiten an. Vernetzen Sie sich mit Kunden, die Ihre Zeit und Sorgfalt schätzen.",

            .onboardingDoneTitle: "Alles bereit",
            .onboardingDoneSubtitle: "Legen wir los",
            .onboardingDoneBody: "Erstellen Sie ein Konto als Folder oder Kunde, vervollständigen Sie Ihr Profil und starten Sie das Matching.",

            .profileTitle: "Profil",
            .profileLogout: "Abmelden",
            .profileClose: "Schließen",
            .profileUpdate: "Aktualisieren",
            .profilePhotoSection: "Profilfoto",
            .chooseProfilePhotoTitle: "Profilfoto auswählen",
            .chooseFromAvatarOption: "Aus Avataren auswählen",
            .chooseFromLibraryOption: "Aus der Galerie auswählen",
            .chooseAvatarTitle: "Avatar auswählen",
            .profileGalleryTitle: "Meine Fotos",
            .profileGalleryAdd: "Hinzufügen",
            .showPhoneNumberToggle: "Meine Telefonnummer anzeigen",
            .showAddressToggle: "Meine Adresse anzeigen",
            .isFolderToggle: "Ich bin Folder",

            .fieldFirstName: "Vorname",
            .fieldLastName: "Nachname",
            .fieldFullName: "Vollständiger Name",
            .fieldEmail: "E-Mail",
            .fieldPhone: "Telefonnummer",
            .fieldChargingFee: "Gebühr",
            .fieldAddress: "Adresse",

            .placeholderFirstName: "Vorname",
            .placeholderLastName: "Nachname",
            .placeholderEmail: "E-Mail-Adresse",
            .placeholderPhone: "Telefonnummer",
            .placeholderChargingFee: "Gebühr",
            .placeholderAddress: "Adresse",

            .addressPrivacy: "Ihre Adresse wird nicht weitergegeben",

            .alertOK: "OK",
            .profileAlertTitle: "Profil",
            .profileErrorFillRequired: "Bitte Vorname, Nachname und Telefonnummer ausfüllen.",
            .profileUpdatedSuccess: "Profil aktualisiert.",

            .appTagline: "Ein sicherer Ort für bedeutungsvolle Verbindungen",
            .loginAlertTitle: "Anmeldung",
            .accountAlertTitle: "Konto",
            .loginSignIn: "Anmelden",
            .loginSignUp: "Registrieren",
            .loginFullName: "Vollständiger Name",
            .loginEnterFullName: "Vollständigen Namen eingeben",
            .loginEmail: "E-Mail",
            .loginEnterEmail: "E-Mail eingeben",
            .loginPassword: "Passwort",
            .loginEnterPassword: "Passwort eingeben",
            .loginConfirmPassword: "Passwort bestätigen",
            .loginConfirmYourPassword: "Passwort bestätigen",
            .loginForgotPassword: "Passwort vergessen?",
            .loginDontHaveAccount: "Noch kein Konto?",
            .loginAlreadyHaveAccount: "Bereits ein Konto?",
            .loginPleaseEnterEmailAndPassword: "Bitte E-Mail und Passwort eingeben.",
            .loginPleaseFillAllFields: "Bitte alle Felder ausfüllen.",
            .loginPasswordsDoNotMatch: "Passwörter stimmen nicht überein.",
            .loginIncorrectCredentials: "E-Mail oder Passwort ist falsch.",
            .loginNoAccountFound: "Kein Konto für diese E-Mail gefunden.",
            .loginInvalidEmail: "Bitte eine gültige E-Mail-Adresse eingeben.",
            .loginEmailInUse: "Diese E-Mail wird bereits verwendet.",
            .loginChooseStrongerPassword: "Bitte ein stärkeres Passwort wählen.",
            .loginCreateFailed: "Konto konnte nicht erstellt werden. Bitte erneut versuchen.",
            .loginEnterEmailFirst: "Bitte zuerst Ihre E-Mail eingeben, dann Passwort vergessen tippen.",
            .loginResetEmailSent: "E-Mail zum Zurücksetzen wurde gesendet.",

            .findTitleProfile: "Profil",
            .findTitleSettings: "Einstellungen",
            .findTitleFolders: "Folder finden",
            .findTitleClients: "Kunden finden",
            .findAudienceLabel: "Zielgruppe",
            .findAudienceFolders: "Folder",
            .findAudienceClients: "Kunden",
            .findLoadingUsers: "Benutzer werden geladen...",
            .findNoResults: "Keine Ergebnisse",
            .findTryChangeFilter: "Versuchen Sie, Suche oder Filter zu ändern.",
            .findFilterAll: "Alle",
            .findFilterFavorites: "Favoriten",
            .findFilterNearby: "In der Nähe",
            .findNoFavorites: "Noch keine Favoriten. Tippe auf den Stern in einem Profil.",
            .findMessage: "Nachricht",
            .findMap: "Karte",
            .findList: "Liste",
            .findMapLoading: "Karte wird geladen…",
            .findMapNoAddresses: "Keine Adressen anzuzeigen. Profile benötigen eine Adresse für die Karte.",
            .findDistanceCalculating: "Entfernung wird ermittelt",
            .findDistanceNoAddress: "Keine Adresse",
            .findDistanceUnavailable: "Entfernung unbekannt",
            .profileFavoriteFolder: "Favoriten-Ordner",
            .profileFavoriteAddedToast: "%@ zu Ihren Favoriten hinzugefügt",
            .errorTitle: "Fehler",
            .statusNew: "Neu",
            .statusActive: "Aktiv",
            .tabFind: "Finden",
            .tabHistory: "Verlauf",
            .tabProfile: "Profil",
            .tabSettings: "Einstellungen",
            .roleFolderUpper: "FOLDER",
            .roleClientUpper: "KUNDE",
            .roleUserUpper: "BENUTZER",
            .roleFolder: "Folder",
            .roleClient: "Kunde",
            .roleUser: "Benutzer",

            .settingsTitle: "Einstellungen",
            .settingsAuthentication: "Authentifizierung",
            .settingsPreferences: "Präferenzen",
            .settingsSupport: "Support",
            .settingsDataManagement: "Datenverwaltung",
            .settingsLanguage: "Sprache",
            .settingsLanguageSubtitle: "App-Sprache auswählen",
            .settingsCurrency: "Währung",
            .settingsCurrencySubtitle: "Automatisch ausgewählt",
            .settingsCurrencyTapToChoose: "Tippen, um Währung zu wählen",
            .selectCurrencyTitle: "Währung wählen",
            .selectCurrencySearchPlaceholder: "Währung suchen",
            .selectCurrencyCancel: "Abbrechen",
            .settingsDarkMode: "Dunkelmodus",
            .settingsDarkModeSubtitle: "Dunkleres Erscheinungsbild verwenden",
            .settingsHelpSupport: "Hilfe & Support",
            .settingsHelpSupportSubtitle: "Hilfe erhalten und Kontakt aufnehmen",
            .settingsTermsPrivacy: "AGB & Datenschutz",
            .settingsTermsPrivacySubtitle: "Richtlinien und Bedingungen ansehen",
            .settingsAbout: "Über",
            .settingsAboutSubtitle: "Version und App-Details",
            .settingsExportData: "Daten exportieren",
            .settingsExportDataSubtitle: "Ihre Daten in eine Datei exportieren",
            .settingsClearAllData: "Alle Daten löschen",
            .settingsClearAllDataSubtitle: "Diese Aktion kann nicht rückgängig gemacht werden",
            .settingsExportComingSoon: "Export kommt bald.",
            .settingsExportAlertTitle: "Daten exportieren",
            .settingsClearAlertTitle: "Alle Daten löschen",
            .settingsClearAlertMessage: "Dadurch werden Ihre lokalen App-Daten dauerhaft gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.",
            .settingsCancel: "Abbrechen",
            .settingsClearAll: "Alles löschen",
            .settingsDone: "Fertig",
            .settingsLogout: "Abmelden",

            .detailsNotProvided: "Nicht angegeben",
            .detailsPhoneHiddenByUser: "%@ telefonnummer aus Datenschutzgründen verborgen",
            .detailsAddressHiddenByUser: "%@ adresse aus Datenschutzgründen verborgen",
            .findPhoneHiddenShort: "Nummer verborgen",

            .livePayTitle: "Live-Sitzung",
            .livePayReadyToStart: "Bereit zum Start",
            .livePaySessionRunning: "Sitzung läuft",
            .livePaySessionEnded: "Sitzung beendet",
            .livePayDuration: "Dauer",
            .livePayPay: "Zahlen",
            .livePaySelectFolderToStart: "Ordner auswählen zum Starten",
            .livePayStopConfirmTitle: "Sitzung beenden?",
            .livePayStopConfirmMessage: "Timer stoppen und Betrag berechnen.",
            .livePayContinue: "Weiter",
            .livePayYesStop: "Beenden",
            .livePayFavoriteFoldersTitle: "Favoriten-Ordner",
            .livePayNoFavoriteFolders: "Noch keine Favoriten. In Suchen hinzufügen.",
            .livePayHourlyRate: "Stundensatz",
            .livePayOtherPays: "Weitere Beträge",
            .livePayFolderToolbar: "Ordner",
            .livePayFindOtherFolders: "Weitere Ordner finden",

            .historyTitle: "Verlauf",
            .historyAll: "Alle",
            .historyExport: "Exportieren",
            .historyEmpty: "Noch kein Zahlungsverlauf.",
            .historyPaid: "Bezahlt",
            .historyPending: "Ausstehend",
            .historyPdfTitle: "Zahlungsverlauf",
            .historyPdfTotalRecords: "Einträge gesamt: %d",
            .historyColumnName: "Name",
            .historyColumnDate: "Datum",
            .historyColumnDuration: "Dauer",
            .historyColumnTotal: "Gesamt",
            .historyColumnStatus: "Status",
            .historyDurationHourOne: "1 Stunde",
            .historyDurationHours: "%d Stunden",
            .historyDurationMinuteOne: "1 Minute",
            .historyDurationMinutes: "%d Minuten",
            .historyDurationAnd: "und",
            .historyDurationZero: "0 Minuten",
            .historyDetailTitle: "Zahlung",
            .historyMarkPaid: "Als bezahlt markieren",

            .messagesTitle: "Nachrichten",
            .messagesLoading: "Laden…",
            .messagesEmpty: "Noch keine Nachrichten",
            .messagesEmptyDescription: "Wenn Sie sich mit Ordnern oder Kunden verbinden, erscheinen Ihre Unterhaltungen hier.",
            .messagesStartBrowsing: "Ordner durchsuchen",
            .messagesSampleCaption: "Vorschau",
            .messagesSampleFolderName: "Beispiel-Ordner",
            .messagesSampleBody: "Passt — ich kann am Samstag vorbeikommen.",
            .messagesErrorNoMessage: "Diese Unterhaltung konnte nicht geöffnet werden.",
            .messagesLoadingConversation: "Unterhaltung wird geladen…",
            .messagesNoMessagesFound: "Keine Nachrichten in diesem Chat.",
            .messagesTypeSomething: "Nachricht",
            .messagesSend: "Senden",
            .matchesPreMessageButton: "Schnellantworten",
            .messagesPreviewPhoto: "Foto",
            .messagesPreviewVoice: "Sprachnachricht",
            .messagesPreviewVoiceDuration: "%@",
            .messagesVoiceRecording: "Aufnahme…",
            .messagesVoiceReady: "Sprachnachricht bereit",
            .messagesYou: "Sie",
            .messagesOtherUser: "Nutzer",
            .messagesImageSaved: "Gespeichert",
            .messagesImageSavedSuccess: "Bild in Fotos gespeichert.",
            .messagesImageSavedFailed: "Bild konnte nicht gespeichert werden.",
            .commonClose: "Schließen",
            .commonSave: "Sichern",
            .commonDelete: "Löschen",
            .tabMessages: "Nachrichten",
            .messagesMicrophoneAlertTitle: "Mikrofon",
            .messagesMicrophoneAlertMessage: "Aktivieren Sie Mikrofonzugriff in den Einstellungen für Sprachnachrichten.",
            .messagesNotificationTitle: "Neue Nachricht",
            .messagesNotificationFrom: "von %@",
            .messagesNotificationOpen: "Nachricht öffnen",
            .messagesNotificationLater: "Später",
            .messagesNewThreadStarter: "Hallo — ich möchte mich zum Wäscheservice austauschen.",
            .messagesStartThreadFailed: "Konversation konnte nicht gestartet werden. Bitte erneut versuchen.",
            .profileNoPhotos: "Keine Fotos",
        ],
        "es": [
            .languageModalTitle: "Idioma",

            .onboardingPrev: "Anterior",
            .onboardingNext: "Siguiente",
            .onboardingGetStarted: "Empezar",

            .onboardingWelcomeTitle: "Bienvenido a Vika",
            .onboardingWelcomeSubtitle: "Ayuda con la ropa, sin complicaciones",
            .onboardingWelcomeBody: "Vika conecta a familias que necesitan ayuda para doblar con Folder locales que te quitan un peso de encima.",

            .onboardingClientTitle: "Soy Cliente",
            .onboardingClientSubtitle: "¿Necesitas ayuda con el montón?",
            .onboardingClientBody: "Publica tu necesidad, explora Folder de confianza cerca de ti y convierte la montaña en pilas ordenadas.",

            .onboardingFolderTitle: "Soy Folder",
            .onboardingFolderSubtitle: "Gana doblando",
            .onboardingFolderBody: "Ofrece ayuda según tu horario. Conéctate con Clientes que valoran tu tiempo y tu cuidado.",

            .onboardingDoneTitle: "Todo listo",
            .onboardingDoneSubtitle: "Empecemos",
            .onboardingDoneBody: "Crea una cuenta como Folder o Cliente, completa tu perfil y empieza a hacer match.",

            .profileTitle: "Perfil",
            .profileLogout: "Cerrar sesión",
            .profileClose: "Cerrar",
            .profileUpdate: "Actualizar",
            .profilePhotoSection: "Foto de perfil",
            .chooseProfilePhotoTitle: "Elegir foto de perfil",
            .chooseFromAvatarOption: "Elegir de Avatares",
            .chooseFromLibraryOption: "Elegir desde la biblioteca",
            .chooseAvatarTitle: "Elegir Avatar",
            .profileGalleryTitle: "Mis fotos",
            .profileGalleryAdd: "Añadir",
            .showPhoneNumberToggle: "Mostrar mi numero de telefono",
            .showAddressToggle: "Mostrar mi direccion",
            .isFolderToggle: "Soy Folder",

            .fieldFirstName: "Nombre",
            .fieldLastName: "Apellidos",
            .fieldFullName: "Nombre completo",
            .fieldEmail: "Correo",
            .fieldPhone: "Teléfono",
            .fieldChargingFee: "Tarifa",
            .fieldAddress: "Dirección",

            .placeholderFirstName: "Nombre",
            .placeholderLastName: "Apellidos",
            .placeholderEmail: "Correo electrónico",
            .placeholderPhone: "Número de teléfono",
            .placeholderChargingFee: "Tarifa",
            .placeholderAddress: "Dirección",

            .addressPrivacy: "Tu dirección no se compartirá",

            .alertOK: "OK",
            .profileAlertTitle: "Perfil",
            .profileErrorFillRequired: "Completa nombre, apellidos y teléfono.",
            .profileUpdatedSuccess: "Perfil actualizado.",

            .appTagline: "Un espacio seguro para conexiones significativas",
            .loginAlertTitle: "Inicio de sesión",
            .accountAlertTitle: "Cuenta",
            .loginSignIn: "Iniciar sesión",
            .loginSignUp: "Registrarse",
            .loginFullName: "Nombre completo",
            .loginEnterFullName: "Introduce tu nombre completo",
            .loginEmail: "Correo",
            .loginEnterEmail: "Introduce tu correo",
            .loginPassword: "Contraseña",
            .loginEnterPassword: "Introduce tu contraseña",
            .loginConfirmPassword: "Confirmar contraseña",
            .loginConfirmYourPassword: "Confirma tu contraseña",
            .loginForgotPassword: "¿Olvidaste tu contraseña?",
            .loginDontHaveAccount: "¿No tienes cuenta?",
            .loginAlreadyHaveAccount: "¿Ya tienes cuenta?",
            .loginPleaseEnterEmailAndPassword: "Introduce tu correo y contraseña.",
            .loginPleaseFillAllFields: "Completa todos los campos.",
            .loginPasswordsDoNotMatch: "Las contraseñas no coinciden.",
            .loginIncorrectCredentials: "Correo o contraseña incorrectos.",
            .loginNoAccountFound: "No se encontró una cuenta para este correo.",
            .loginInvalidEmail: "Introduce una dirección de correo válida.",
            .loginEmailInUse: "Este correo ya está en uso.",
            .loginChooseStrongerPassword: "Elige una contraseña más segura.",
            .loginCreateFailed: "No se pudo crear la cuenta. Inténtalo de nuevo.",
            .loginEnterEmailFirst: "Primero introduce tu correo y luego pulsa ¿Olvidaste tu contraseña?.",
            .loginResetEmailSent: "Correo de restablecimiento enviado.",

            .findTitleProfile: "Perfil",
            .findTitleSettings: "Ajustes",
            .findTitleFolders: "Buscar Folders",
            .findTitleClients: "Buscar Clientes",
            .findAudienceLabel: "Audiencia",
            .findAudienceFolders: "Folders",
            .findAudienceClients: "Clientes",
            .findLoadingUsers: "Cargando usuarios...",
            .findNoResults: "Sin resultados",
            .findTryChangeFilter: "Prueba cambiando tu búsqueda o el filtro.",
            .findFilterAll: "Todos",
            .findFilterFavorites: "Favoritos",
            .findFilterNearby: "Cercanos",
            .findNoFavorites: "Aún no hay carpetas favoritas. Toca la estrella en un perfil.",
            .findMessage: "Mensaje",
            .findMap: "Mapa",
            .findList: "Lista",
            .findMapLoading: "Cargando mapa…",
            .findMapNoAddresses: "No hay direcciones que mostrar. Los perfiles necesitan una dirección para aparecer en el mapa.",
            .findDistanceCalculating: "Actualizando distancia",
            .findDistanceNoAddress: "Sin dirección",
            .findDistanceUnavailable: "Distancia no disponible",
            .profileFavoriteFolder: "Carpeta favorita",
            .profileFavoriteAddedToast: "%@ añadido a tus favoritos",
            .errorTitle: "Error",
            .statusNew: "Nuevo",
            .statusActive: "Activo",
            .tabFind: "Buscar",
            .tabHistory: "Historial",
            .tabProfile: "Perfil",
            .tabSettings: "Ajustes",
            .roleFolderUpper: "FOLDER",
            .roleClientUpper: "CLIENTE",
            .roleUserUpper: "USUARIO",
            .roleFolder: "Folder",
            .roleClient: "Cliente",
            .roleUser: "Usuario",

            .settingsTitle: "Ajustes",
            .settingsAuthentication: "Autenticación",
            .settingsPreferences: "Preferencias",
            .settingsSupport: "Soporte",
            .settingsDataManagement: "Gestión de datos",
            .settingsLanguage: "Idioma",
            .settingsLanguageSubtitle: "Elige el idioma de la app",
            .settingsCurrency: "Moneda",
            .settingsCurrencySubtitle: "Selección automática",
            .settingsCurrencyTapToChoose: "Toca para elegir moneda",
            .selectCurrencyTitle: "Elegir moneda",
            .selectCurrencySearchPlaceholder: "Buscar moneda",
            .selectCurrencyCancel: "Cancelar",
            .settingsDarkMode: "Modo oscuro",
            .settingsDarkModeSubtitle: "Usar una apariencia más oscura",
            .settingsHelpSupport: "Ayuda y soporte",
            .settingsHelpSupportSubtitle: "Obtén ayuda y contáctanos",
            .settingsTermsPrivacy: "Términos y privacidad",
            .settingsTermsPrivacySubtitle: "Revisa políticas y términos",
            .settingsAbout: "Acerca de",
            .settingsAboutSubtitle: "Versión y detalles de la app",
            .settingsExportData: "Exportar datos",
            .settingsExportDataSubtitle: "Exporta tus datos a un archivo",
            .settingsClearAllData: "Borrar todos los datos",
            .settingsClearAllDataSubtitle: "Esto no se puede deshacer",
            .settingsExportComingSoon: "La exportación estará disponible pronto.",
            .settingsExportAlertTitle: "Exportar datos",
            .settingsClearAlertTitle: "Borrar todos los datos",
            .settingsClearAlertMessage: "Esto eliminará permanentemente tus datos locales. Esta acción no se puede deshacer.",
            .settingsCancel: "Cancelar",
            .settingsClearAll: "Borrar todo",
            .settingsDone: "Listo",
            .settingsLogout: "Cerrar sesión",

            .detailsNotProvided: "No proporcionado",
            .detailsPhoneHiddenByUser: "%@ número de teléfono oculto por privacidad",
            .detailsAddressHiddenByUser: "%@ dirección oculta por privacidad",
            .findPhoneHiddenShort: "Número oculto",

            .livePayTitle: "Sesión en vivo",
            .livePayReadyToStart: "Listo para empezar",
            .livePaySessionRunning: "Sesión en curso",
            .livePaySessionEnded: "Sesión finalizada",
            .livePayDuration: "Duración",
            .livePayPay: "Pagar",
            .livePaySelectFolderToStart: "Selecciona una carpeta para empezar",
            .livePayStopConfirmTitle: "¿Detener sesión?",
            .livePayStopConfirmMessage: "Parar el temporizador y calcular el pago.",
            .livePayContinue: "Continuar",
            .livePayYesStop: "Detener",
            .livePayFavoriteFoldersTitle: "Carpetas favoritas",
            .livePayNoFavoriteFolders: "Sin favoritos. Añádelas desde Buscar.",
            .livePayHourlyRate: "Tarifa por hora",
            .livePayOtherPays: "Otros pagos",
            .livePayFolderToolbar: "Carpeta",
            .livePayFindOtherFolders: "Buscar otras carpetas",

            .historyTitle: "Historial",
            .historyAll: "Todos",
            .historyExport: "Exportar",
            .historyEmpty: "Aún no hay historial de pagos.",
            .historyPaid: "Pagado",
            .historyPending: "Pendiente",
            .historyPdfTitle: "Historial de pagos",
            .historyPdfTotalRecords: "Registros totales: %d",
            .historyColumnName: "Nombre",
            .historyColumnDate: "Fecha",
            .historyColumnDuration: "Duración",
            .historyColumnTotal: "Total",
            .historyColumnStatus: "Estado",
            .historyDurationHourOne: "1 hora",
            .historyDurationHours: "%d horas",
            .historyDurationMinuteOne: "1 minuto",
            .historyDurationMinutes: "%d minutos",
            .historyDurationAnd: "y",
            .historyDurationZero: "0 minutos",
            .historyDetailTitle: "Pago",
            .historyMarkPaid: "Marcar como pagado",

            .messagesTitle: "Mensajes",
            .messagesLoading: "Cargando…",
            .messagesEmpty: "Aún no hay mensajes",
            .messagesEmptyDescription: "Cuando te conectes con carpetas o clientes, tus conversaciones aparecerán aquí.",
            .messagesStartBrowsing: "Explorar carpetas",
            .messagesSampleCaption: "Vista previa",
            .messagesSampleFolderName: "Carpeta de ejemplo",
            .messagesSampleBody: "Genial — puedo pasar el sábado.",
            .messagesErrorNoMessage: "No se pudo abrir esta conversación.",
            .messagesLoadingConversation: "Cargando conversación…",
            .messagesNoMessagesFound: "No hay mensajes en este hilo.",
            .messagesTypeSomething: "Mensaje",
            .messagesSend: "Enviar",
            .matchesPreMessageButton: "Respuestas rápidas",
            .messagesPreviewPhoto: "Foto",
            .messagesPreviewVoice: "Mensaje de voz",
            .messagesPreviewVoiceDuration: "%@",
            .messagesVoiceRecording: "Grabando…",
            .messagesVoiceReady: "Listo para enviar voz",
            .messagesYou: "Tú",
            .messagesOtherUser: "Usuario",
            .messagesImageSaved: "Guardado",
            .messagesImageSavedSuccess: "Imagen guardada en Fotos.",
            .messagesImageSavedFailed: "No se pudo guardar la imagen.",
            .commonClose: "Cerrar",
            .commonSave: "Guardar",
            .commonDelete: "Eliminar",
            .tabMessages: "Mensajes",
            .messagesMicrophoneAlertTitle: "Micrófono",
            .messagesMicrophoneAlertMessage: "Activa el micrófono en Ajustes para enviar mensajes de voz.",
            .messagesNotificationTitle: "Nuevo mensaje",
            .messagesNotificationFrom: "de %@",
            .messagesNotificationOpen: "Abrir mensaje",
            .messagesNotificationLater: "Más tarde",
            .messagesNewThreadStarter: "Hola — me gustaría conectar contigo sobre el servicio de lavandería.",
            .messagesStartThreadFailed: "No se pudo iniciar la conversación. Inténtalo de nuevo.",
            .profileNoPhotos: "Sin fotos",
        ],
        "sv": [
            .languageModalTitle: "Språk",

            .onboardingPrev: "Tillbaka",
            .onboardingNext: "Nästa",
            .onboardingGetStarted: "Kom igång",

            .onboardingWelcomeTitle: "Välkommen till Vika",
            .onboardingWelcomeSubtitle: "Tvätthjälp, enkelt och tydligt",
            .onboardingWelcomeBody: "Vika kopplar ihop familjer som behöver hjälp att vika med lokala Foldrar som kan ta hand om högen.",

            .onboardingClientTitle: "Jag är kund",
            .onboardingClientSubtitle: "Behöver du hjälp med högen?",
            .onboardingClientBody: "Publicera ditt behov, hitta pålitliga Foldrar i närheten och få ordning på tvättberget.",

            .onboardingFolderTitle: "Jag är Folder",
            .onboardingFolderSubtitle: "Tjäna på att vika",
            .onboardingFolderBody: "Erbjud hjälp när det passar dig. Möt kunder som uppskattar din tid och omsorg.",

            .onboardingDoneTitle: "Du är redo",
            .onboardingDoneSubtitle: "Nu kör vi",
            .onboardingDoneBody: "Skapa konto som Folder eller kund, fyll i din profil och börja matcha.",

            .profileTitle: "Profil",
            .profileLogout: "Logga ut",
            .profileClose: "Stäng",
            .profileUpdate: "Uppdatera",
            .profilePhotoSection: "Profilfoto",
            .chooseProfilePhotoTitle: "Välj profilfoto",
            .chooseFromAvatarOption: "Välj från avatarer",
            .chooseFromLibraryOption: "Välj från biblioteket",
            .chooseAvatarTitle: "Välj avatar",
            .profileGalleryTitle: "Mina foton",
            .profileGalleryAdd: "Lägg till",
            .showPhoneNumberToggle: "Visa mitt telefonnummer",
            .showAddressToggle: "Visa min adress",
            .isFolderToggle: "Jag är Folder",

            .fieldFirstName: "Förnamn",
            .fieldLastName: "Efternamn",
            .fieldFullName: "Fullständigt namn",
            .fieldEmail: "E-post",
            .fieldPhone: "Telefon",
            .fieldChargingFee: "Avgift",
            .fieldAddress: "Adress",

            .placeholderFirstName: "Förnamn",
            .placeholderLastName: "Efternamn",
            .placeholderEmail: "E-postadress",
            .placeholderPhone: "Telefonnummer",
            .placeholderChargingFee: "Avgift",
            .placeholderAddress: "Adress",

            .addressPrivacy: "Din adress delas inte",

            .alertOK: "OK",
            .profileAlertTitle: "Profil",
            .profileErrorFillRequired: "Fyll i förnamn, efternamn och telefonnummer.",
            .profileUpdatedSuccess: "Profilen uppdaterades.",

            .appTagline: "En trygg plats för meningsfulla kontakter",
            .loginAlertTitle: "Inloggning",
            .accountAlertTitle: "Konto",
            .loginSignIn: "Logga in",
            .loginSignUp: "Skapa konto",
            .loginFullName: "Fullständigt namn",
            .loginEnterFullName: "Ange ditt fullständiga namn",
            .loginEmail: "E-post",
            .loginEnterEmail: "Ange din e-post",
            .loginPassword: "Lösenord",
            .loginEnterPassword: "Ange ditt lösenord",
            .loginConfirmPassword: "Bekräfta lösenord",
            .loginConfirmYourPassword: "Bekräfta ditt lösenord",
            .loginForgotPassword: "Glömt lösenordet?",
            .loginDontHaveAccount: "Har du inget konto?",
            .loginAlreadyHaveAccount: "Har du redan ett konto?",
            .loginPleaseEnterEmailAndPassword: "Ange e-post och lösenord.",
            .loginPleaseFillAllFields: "Fyll i alla fält.",
            .loginPasswordsDoNotMatch: "Lösenorden matchar inte.",
            .loginIncorrectCredentials: "Fel e-post eller lösenord.",
            .loginNoAccountFound: "Inget konto hittades för den här e-posten.",
            .loginInvalidEmail: "Ange en giltig e-postadress.",
            .loginEmailInUse: "Den här e-posten används redan.",
            .loginChooseStrongerPassword: "Välj ett starkare lösenord.",
            .loginCreateFailed: "Kunde inte skapa konto. Försök igen.",
            .loginEnterEmailFirst: "Ange först din e-post och tryck sedan på Glömt lösenordet.",
            .loginResetEmailSent: "E-post för återställning skickad.",

            .findTitleProfile: "Profil",
            .findTitleSettings: "Inställningar",
            .findTitleFolders: "Hitta Folders",
            .findTitleClients: "Hitta kunder",
            .findAudienceLabel: "Målgrupp",
            .findAudienceFolders: "Folders",
            .findAudienceClients: "Kunder",
            .findLoadingUsers: "Laddar användare...",
            .findNoResults: "Inga resultat",
            .findTryChangeFilter: "Försök ändra sökningen eller filtret.",
            .findFilterAll: "Alla",
            .findFilterFavorites: "Favoriter",
            .findFilterNearby: "Nära",
            .findNoFavorites: "Inga favoritmappar än. Tryck på stjärnan på en profil.",
            .findMessage: "Meddelande",
            .findMap: "Karta",
            .findList: "Lista",
            .findMapLoading: "Laddar karta…",
            .findMapNoAddresses: "Inga adresser att visa. Profiler behöver en adress för att visas på kartan.",
            .findDistanceCalculating: "Uppdaterar avstånd",
            .findDistanceNoAddress: "Ingen adress",
            .findDistanceUnavailable: "Avstånd saknas",
            .profileFavoriteFolder: "Favoritmapp",
            .profileFavoriteAddedToast: "%@ har lagts till bland dina favoriter",
            .errorTitle: "Fel",
            .statusNew: "Ny",
            .statusActive: "Aktiv",
            .tabFind: "Hitta",
            .tabHistory: "Historik",
            .tabProfile: "Profil",
            .tabSettings: "Inställningar",
            .roleFolderUpper: "FOLDER",
            .roleClientUpper: "KUND",
            .roleUserUpper: "ANVÄNDARE",
            .roleFolder: "Folder",
            .roleClient: "Kund",
            .roleUser: "Användare",

            .settingsTitle: "Inställningar",
            .settingsAuthentication: "Autentisering",
            .settingsPreferences: "Inställningar",
            .settingsSupport: "Support",
            .settingsDataManagement: "Datahantering",
            .settingsLanguage: "Språk",
            .settingsLanguageSubtitle: "Välj appens språk",
            .settingsCurrency: "Valuta",
            .settingsCurrencySubtitle: "Väljs automatiskt",
            .settingsCurrencyTapToChoose: "Tryck för att välja valuta",
            .selectCurrencyTitle: "Välj valuta",
            .selectCurrencySearchPlaceholder: "Sök valuta",
            .selectCurrencyCancel: "Avbryt",
            .settingsDarkMode: "Mörkt läge",
            .settingsDarkModeSubtitle: "Använd ett mörkare utseende",
            .settingsHelpSupport: "Hjälp och support",
            .settingsHelpSupportSubtitle: "Få hjälp och kontakta oss",
            .settingsTermsPrivacy: "Villkor och integritet",
            .settingsTermsPrivacySubtitle: "Granska policyer och villkor",
            .settingsAbout: "Om",
            .settingsAboutSubtitle: "Version och appdetaljer",
            .settingsExportData: "Exportera data",
            .settingsExportDataSubtitle: "Exportera dina data till en fil",
            .settingsClearAllData: "Rensa all data",
            .settingsClearAllDataSubtitle: "Detta kan inte ångras",
            .settingsExportComingSoon: "Export kommer snart.",
            .settingsExportAlertTitle: "Exportera data",
            .settingsClearAlertTitle: "Rensa all data",
            .settingsClearAlertMessage: "Detta raderar dina lokala appdata permanent. Åtgärden kan inte ångras.",
            .settingsCancel: "Avbryt",
            .settingsClearAll: "Rensa allt",
            .settingsDone: "Klar",
            .settingsLogout: "Logga ut",

            .detailsNotProvided: "Ej angivet",
            .detailsPhoneHiddenByUser: "%@ telefonnummer dold av integritetsskäl",
            .detailsAddressHiddenByUser: "%@ adress dold av integritetsskäl",
            .findPhoneHiddenShort: "Nummer dolt",

            .livePayTitle: "Livepass",
            .livePayReadyToStart: "Redo att starta",
            .livePaySessionRunning: "Pass pågår",
            .livePaySessionEnded: "Pass avslutat",
            .livePayDuration: "Tid",
            .livePayPay: "Betala",
            .livePaySelectFolderToStart: "Välj en mapp för att starta",
            .livePayStopConfirmTitle: "Avsluta pass?",
            .livePayStopConfirmMessage: "Stoppa timern och beräkna betalning.",
            .livePayContinue: "Fortsätt",
            .livePayYesStop: "Stoppa",
            .livePayFavoriteFoldersTitle: "Favoritmappar",
            .livePayNoFavoriteFolders: "Inga favoriter än. Lägg till under Hitta.",
            .livePayHourlyRate: "Timtaxa",
            .livePayOtherPays: "Övriga belopp",
            .livePayFolderToolbar: "Mapp",
            .livePayFindOtherFolders: "Hitta fler mappar",

            .historyTitle: "Historik",
            .historyAll: "Alla",
            .historyExport: "Exportera",
            .historyEmpty: "Ingen betalningshistorik ännu.",
            .historyPaid: "Betald",
            .historyPending: "Väntande",
            .historyPdfTitle: "Betalningshistorik",
            .historyPdfTotalRecords: "Antal poster: %d",
            .historyColumnName: "Namn",
            .historyColumnDate: "Datum",
            .historyColumnDuration: "Längd",
            .historyColumnTotal: "Totalt",
            .historyColumnStatus: "Status",
            .historyDurationHourOne: "1 timme",
            .historyDurationHours: "%d timmar",
            .historyDurationMinuteOne: "1 minut",
            .historyDurationMinutes: "%d minuter",
            .historyDurationAnd: "och",
            .historyDurationZero: "0 minuter",
            .historyDetailTitle: "Betalning",
            .historyMarkPaid: "Markera som betald",

            .messagesTitle: "Meddelanden",
            .messagesLoading: "Laddar…",
            .messagesEmpty: "Inga meddelanden än",
            .messagesEmptyDescription: "När du kopplar ihop med mappar eller klienter visas dina konversationer här.",
            .messagesStartBrowsing: "Bläddra mappar",
            .messagesSampleCaption: "Förhandsvisning",
            .messagesSampleFolderName: "Exempelmapp",
            .messagesSampleBody: "Låter bra — jag kan hämta på lördag.",
            .messagesErrorNoMessage: "Kunde inte öppna konversationen.",
            .messagesLoadingConversation: "Laddar konversation…",
            .messagesNoMessagesFound: "Inga meddelanden i den här tråden.",
            .messagesTypeSomething: "Meddelande",
            .messagesSend: "Skicka",
            .matchesPreMessageButton: "Snabbsvar",
            .messagesPreviewPhoto: "Foto",
            .messagesPreviewVoice: "Röstmeddelande",
            .messagesPreviewVoiceDuration: "%@",
            .messagesVoiceRecording: "Spelar in…",
            .messagesVoiceReady: "Röst redo",
            .messagesYou: "Du",
            .messagesOtherUser: "Användare",
            .messagesImageSaved: "Sparat",
            .messagesImageSavedSuccess: "Bilden sparades i Foton.",
            .messagesImageSavedFailed: "Kunde inte spara bilden.",
            .commonClose: "Stäng",
            .commonSave: "Spara",
            .commonDelete: "Radera",
            .tabMessages: "Meddelanden",
            .messagesMicrophoneAlertTitle: "Mikrofon",
            .messagesMicrophoneAlertMessage: "Aktivera mikrofonåtkomst under Inställningar för röstmeddelanden.",
            .messagesNotificationTitle: "Nytt meddelande",
            .messagesNotificationFrom: "från %@",
            .messagesNotificationOpen: "Öppna meddelande",
            .messagesNotificationLater: "Senare",
            .messagesNewThreadStarter: "Hej — jag vill gärna prata om tvättstöd.",
            .messagesStartThreadFailed: "Det gick inte att starta konversationen. Försök igen.",
            .profileNoPhotos: "Inga foton",
        ],
    ]

    static func t(_ key: Key, languageCode: String) -> String {
        let lang = Language.language(forCode: languageCode).code
        if let value = table[lang]?[key] { return value }
        if let fallback = table["en"]?[key] { return fallback }
        return key.rawValue
    }
}
