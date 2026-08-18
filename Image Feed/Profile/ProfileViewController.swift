import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    
    // MARK: - UI Elements (теперь все опциональные)
    private var avatarImageView: UIImageView?
    private var nameLabel: UILabel?
    private var loginNameLabel: UILabel?
    private var descriptionLabel: UILabel?
    private var logoutButton: UIButton?
    
    // MARK: - Properties
    private let profileService = ProfileService.shared
    private var profileImageServiceObserver: NSObjectProtocol?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateProfileDetails()
        observeAvatarChanges()
        updateAvatar()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = UIColor(named: "YP Black")
        
        // Аватар
        let avatar = UIImageView()
        avatar.image = UIImage(named: "avatar")
        avatar.layer.cornerRadius = 35
        avatar.layer.masksToBounds = true
        avatar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatar)
        avatarImageView = avatar
        
        // Имя
        let name = UILabel()
        name.text = "Екатерина Новикова"
        name.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        name.textColor = .white
        name.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(name)
        nameLabel = name
        
        // Логин
        let login = UILabel()
        login.text = "@ekaterina_nov"
        login.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        login.textColor = UIColor(red: 174/255, green: 175/255, blue: 180/255, alpha: 1)
        login.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(login)
        loginNameLabel = login
        
        // Описание
        let description = UILabel()
        description.text = "Hello, world!"
        description.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        description.textColor = .white
        description.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(description)
        descriptionLabel = description
        
        // Кнопка выхода
        guard let logoutImage = UIImage(systemName: "ipad.and.arrow.forward") else {
            return
        }
        let button = UIButton.systemButton(
            with: logoutImage,
            target: self,
            action: #selector(didTapLogoutButton)
        )
        button.tintColor = UIColor(red: 245/255, green: 107/255, blue: 108/255, alpha: 1)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        logoutButton = button
        
        // Констрейнты
        NSLayoutConstraint.activate([
            avatar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            avatar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            avatar.widthAnchor.constraint(equalToConstant: 70),
            avatar.heightAnchor.constraint(equalToConstant: 70),
            
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 45),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44),
            
            name.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 34),
            name.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            name.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            login.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 8),
            login.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            login.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            description.topAnchor.constraint(equalTo: login.bottomAnchor, constant: 8),
            description.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            description.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - Update Profile Details
    private func updateProfileDetails() {
        guard let profile = profileService.profile else { return }
        
        nameLabel?.text = profile.name
        loginNameLabel?.text = profile.loginName
        descriptionLabel?.text = profile.bio ?? ""
    }
    
    // MARK: - Avatar
    private func observeAvatarChanges() {
        profileImageServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ProfileImageService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.updateAvatar()
            }
    }
    
    private func updateAvatar() {
        guard
            let avatarURLString = ProfileImageService.shared.avatarURL,
            let avatarURL = URL(string: avatarURLString),
            let avatarImageView = avatarImageView
        else {
            avatarImageView?.image = UIImage(named: "avatar")
            return
        }
        
        let placeholder = UIImage(named: "avatar")
        let processor = RoundCornerImageProcessor(cornerRadius: 35)
        
        avatarImageView.kf.setImage(
            with: avatarURL,
            placeholder: placeholder,
            options: [
                .processor(processor),
                .cacheSerializer(FormatIndicatedCacheSerializer.png)
            ]
        )
    }
    
    // MARK: - Logout
    @objc private func didTapLogoutButton() {
        let alert = UIAlertController(
            title: "Выход из аккаунта",
            message: "Ты уверена, что хочешь выйти?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Выйти", style: .destructive) { [weak self] _ in
            self?.logout()
        })
        
        present(alert, animated: true)
    }
    
    private func logout() {
        OAuth2TokenStorage.shared.token = nil
        Kingfisher.ImageCache.default.clearMemoryCache()
        Kingfisher.ImageCache.default.clearDiskCache()
        
        guard let window = UIApplication.shared.windows.first else {
            return
        }
        
        window.rootViewController = SplashViewController()
    }
}
