//
//  ContentView.swift
//  ChatApp
//
//  Created by Tymoteusz Kosman on 07/02/2023.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore


struct LoginView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    
    @State var shouldShowImagePicker = false
    
    var body: some View {
        
        NavigationView {
            ScrollView {
                
                VStack(spacing: 16) {
                    Picker(selection: $isLoginMode, label: Text("Picker here")) {
                        Text("Log in")
                            .tag(true)
                        Text("Create Acoount")
                            .tag(false)
                        
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    if !isLoginMode {
                        Button {
                            shouldShowImagePicker.toggle()
                        } label: {
                            
                            VStack{
                                if let image = self.image{
                                    Image(uiImage: image)
                                        .resizable()
                                        .frame(width: 128, height: 128)
                                        .scaledToFill()
                                        .cornerRadius(64)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .padding()
                                        .foregroundColor(Color(.label))
                                }
                            }
                            .overlay(RoundedRectangle(cornerRadius: 64).stroke(Color.black, lineWidth: 3))
                        }
                    }
                    
                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Password", text: $password)
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(15)
                    
                    Button {
                        handleAction()
                    } label: {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "Log in" : "Create Account")
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }.background(Color.blue).cornerRadius(15)
                        
                    }
                    
                    Text(self.loginStatusMessage)
                        .foregroundColor(.red)
                }
                .padding()
                

            }
            .navigationTitle(isLoginMode ? "Log in" : "Create Account")
            .background(Color(.init(white:0, alpha: 0.05))
                .ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil){
            ImagePicker(image: $image)
        }
    }
    
    @State var image: UIImage?
    
    private func handleAction(){
        if isLoginMode{
            loginUser()
        }else{
            createNewAccount()
        }
    }
    
    private func loginUser(){
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password){
            result, err in
            if let err = err {
                print("Failed to log in user", err)
                self.loginStatusMessage = "Failed to log in user: \(err)"
                return
            }
            print("Succesfully logged in as user: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "Succesfully logged in as user: \(result?.user.uid ?? "")"
            
            self.didCompleteLoginProcess()
        }
    }
    
    @State var loginStatusMessage = ""
    
    private func createNewAccount(){
        if self.image == nil {
            self.loginStatusMessage = "You must select an avatar"
            return
        }
        
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password){
            result, err in
            if let err = err {
                print("Failed to create user", err)
                self.loginStatusMessage = "Failed to create user: \(err)"
                return
            }
            print("Succesfully crated user: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "Succesfully crated user: \(result?.user.uid ?? "")"
            
            self.persistImageToStorage()
        }
    }
    
    private func persistImageToStorage(){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
            else {return}
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else {return}
        
        ref.putData(imageData, metadata: nil) {metadata, err in
            if let err = err {
                self.loginStatusMessage = "Failed to push image to storage: \(err)"
                return
            }
            ref.downloadURL {url, err in
                if let err = err {
                    self.loginStatusMessage = "Failed to retrieve dwonloadURL: \(err)"
                    return
                }
                self.loginStatusMessage = "Succesfully stored image with url: \(url?.absoluteString ?? "")"
                
                guard let url = url else {return}
                self.storeUserInformation(imageProfileUrl: url)
            }
        }

    }
    
    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {return}
        let userData = ["email": self.email, "uid": uid, "profileImageUrl": imageProfileUrl.absoluteString]
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData) {err in
                if let err = err {
                    print(err)
                    self.loginStatusMessage = "\(err)"
                    return
                }
                
                print("success")
                
                self.didCompleteLoginProcess()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {
            
        })
    }
}