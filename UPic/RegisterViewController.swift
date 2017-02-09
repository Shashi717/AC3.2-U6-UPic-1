//
//  RegisterViewController.swift
//  UPic
//
//  Created by Marcel Chaucer on 2/7/17.
//  Copyright © 2017 Eric Chang. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class RegisterViewController: UIViewController, CellTitled, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var titleForCell = "REGISTER"
    var ref: FIRDatabaseReference!
    var activeField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewHierarchy()
        configureConstraints()
        
        // Do any additional setup after loading the view.
    }

    func configureConstraints() {
        // Image View
        profilePic.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 200.0, height: 200.0))
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(75.0)
        }
        
        // Containers
        usernameTextField.snp.makeConstraints { (make) in
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalTo(44.0)
            make.centerX.equalToSuperview()
            make.top.equalTo(profilePic.snp.bottom).offset(100.0)
        }
        
        emailTextField.snp.makeConstraints { (make) in
            make.width.equalTo(usernameTextField.snp.width)
            make.height.equalTo(usernameTextField.snp.height)
            make.centerX.equalToSuperview()
            make.top.equalTo(usernameTextField.snp.bottom).offset(20.0)
        }
        
        passwordTextField.snp.makeConstraints { (make) in
            make.width.equalTo(emailTextField.snp.width)
            make.height.equalTo(emailTextField.snp.height)
            make.centerX.equalToSuperview()
            make.top.equalTo(emailTextField.snp.bottom).offset(20.0)
        }

        
        // Buttons
        doneButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.view.snp.bottom).inset(30.0)
        }
    }
    
    func setupViewHierarchy() {
        self.edgesForExtendedLayout = []
        self.view.backgroundColor = ColorPalette.primaryColor
        self.tabBarController?.title = titleForCell
        
        view.addSubview(doneButton)
        view.addSubview(emailTextField)
        view.addSubview(usernameTextField)
        view.addSubview(passwordTextField)
        view.addSubview(profilePic)
        
        doneButton.addTarget(self, action: #selector(didTapDone(sender:)), for: .touchUpInside)
        
    }
    
    //MARK:- UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        activeField = nil
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.passwordTextField {
            self.view.endEditing(true)
            return false
        }
        return true
    }
    
    func didTapDone(sender: UIButton) {
        
        if let email = emailTextField.text, let password = passwordTextField.text {
            FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user: FIRUser?, error: Error?) in
                if user != nil {
                    // We Have A User
                    
                    self.ref = FIRDatabase.database().reference()
                    let imageName = NSUUID().uuidString
                    let storageRef = FIRStorage.storage().reference().child("\(imageName).png")
                    
                    if let uploadData = UIImagePNGRepresentation(self.profilePic.image!) {
                        storageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
                           
                            if error != nil {
                                print(error)
                                return
                            }
                            
                            if let metadataURL = metadata?.downloadURL()?.absoluteString {
                                let values = [
                                    "password": self.passwordTextField.text!,
                                    "username": self.usernameTextField.text!,
                                    "email" : self.emailTextField.text!,
                                    "profileImageURL": metadataURL
                                ]
                                self.registerUser(uid: (user?.uid)! ,values: values)
                            }
                        })
                    }
                }
            })
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    // Helper Function To Register User
    func registerUser(uid: String, values: [String: String]) {
        self.ref = FIRDatabase.database().reference()
        self.ref.child("users").child(uid).setValue(values)
    }
    
    
    // Handler Function for picking profile pic
    func pickProfileImage() {
        let picker = UIImagePickerController()
        present(picker, animated: true, completion: nil)
        picker.delegate = self
    }
    
   // MARK: - Image Picker Delegate Method
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dump(info["UIImagePickerControllerOriginalImage"])
        dump(info)
        self.profilePic.image = info["UIImagePickerControllerOriginalImage"] as! UIImage?
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Lazy Instantiates
    // Image View
    lazy var profilePic: UIImageView = {
        let profilePic = UIImageView()
        profilePic.image = #imageLiteral(resourceName: "user_icon")
        profilePic.contentMode = .scaleAspectFit
        profilePic.layer.cornerRadius = 100
        profilePic.layer.masksToBounds = true
        profilePic.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pickProfileImage)))
        profilePic.isUserInteractionEnabled = true
        
        return profilePic
    }()
    
    // Buttons
    internal lazy var doneButton: UIButton = {
        let button: UIButton = UIButton(type: .roundedRect)
        button.setTitle("DONE", for: .normal)
        button.backgroundColor = ColorPalette.primaryColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: UIFontWeightMedium)
        button.setTitleColor(ColorPalette.textIconColor, for: .normal)
        button.layer.cornerRadius = 4.0
        button.layer.borderColor = ColorPalette.textIconColor.cgColor
        button.layer.borderWidth = 2.0
        button.contentEdgeInsets = UIEdgeInsetsMake(8.0, 24.0, 8.0, 24.0)
        return button
    }()
    
    // Textfields
    internal lazy var usernameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "USERNAME"
        textField.textColor = ColorPalette.accentColor
        textField.tintColor = ColorPalette.accentColor
        textField.borderStyle = .bezel
        return textField
    }()
    
    internal lazy var emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "EMAIL"
        textField.textColor = ColorPalette.accentColor
        textField.tintColor = ColorPalette.accentColor
        textField.borderStyle = .bezel
        return textField
    }()
    
    internal lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "PASSWORD"
        textField.textColor = ColorPalette.accentColor
        textField.tintColor = ColorPalette.accentColor
        textField.borderStyle = .bezel
        textField.isSecureTextEntry = true
        return textField
    }()
}
