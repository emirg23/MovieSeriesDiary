//
//  LoginPage.swift
//  MovieSeriesDiary
//
//  Created by Emir Gökalp on 1.05.2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginPage: View {
    @ObservedObject var vM: BindingPageViewModel
    @ObservedObject var loginVM: LoginPageViewModel
    var firstPage = true

    init(firstPage: Bool = true, vM: BindingPageViewModel, loginVM: LoginPageViewModel) {
        self.firstPage = firstPage
        self.vM = vM
        self.loginVM = loginVM
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Spacer()
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                    VStack {
                        Text("Movie/Series\nDiary")
                            .font(.system(size: 30, weight: .bold))
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 40)
                
                if loginVM.logging {
                    ZStack {
                        Color.black.opacity(0.01)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    loginVM.logging = false
                                    loginVM.failText = " "
                                }
                            }
                        VStack {
                            Text(loginVM.failText)
                                .font(.system(size: 20))
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                            loginTable()
                        }
                    }
                } else if loginVM.registering {
                    ZStack {
                        Color.black.opacity(0.01)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    loginVM.registering = false
                                    loginVM.failText = " "
                                }
                            }
                        VStack {
                            Text(loginVM.failText)
                                .font(.system(size: 20))
                                .foregroundStyle(.red.opacity(0.75))
                                .multilineTextAlignment(.center)
                            registerTable()
                        }
                    }
                } else {
                    Spacer()

                    Text("Track everything you watch.\nStay organized, stay inspired.")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .foregroundStyle(.text.opacity(0.75))
                }
                Spacer()
                if !loginVM.logging && !loginVM.registering {
                    buttonsPart()
                }
            }
            .foregroundStyle(.text)
            .background(
                ZStack {
                    if firstPage {
                        NavigationLink(
                            destination: BindingPage(vM: vM).navigationBarBackButtonHidden(),
                            isActive: $loginVM.navigate,
                            label: {
                                EmptyView()
                            }
                        )
                        .onAppear {
                            loginVM.fetchEverything() { series, movies in
                                vM.seriesList = series
                                vM.moviesList = movies
                            }
                            if vM.user != nil {
                                loginVM.navigate = true
                            }
                        }
                    }
                    
                    Image("backgroundImage")
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 20)  
                        .opacity(0.3)
                    Color.back.opacity(0.3)
                }
                    .ignoresSafeArea()
            )
        }
        .onChange(of: loginVM.failed) {
            if loginVM.failed {
                loginVM.loading = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        loginVM.failed = false
                    }
                }
            }
        }
        .tint(Color("textColor"))
    }
    
    func buttonsPart() -> some View {
        VStack {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    loginVM.logging = true
                }
            } label: {
                Text("Log in")
                    .font(.headline)
                    .padding(10)
                    .padding(.horizontal, 70)
                    .background(.accent)
                    .cornerRadius(10)
            }
            .padding(.vertical, 10)
            
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    loginVM.registering = true
                }
            } label: {
                Text("Register")
                    .font(.headline)
                    .padding(10)
                    .padding(.horizontal, 70)
                    .background(Color("secondAccentColor"))
                    .cornerRadius(10)
            }
            .padding(.vertical, 10)
            
            if firstPage {
                HStack {
                    Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                    Text("or")
                        .foregroundColor(.gray)
                    Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)
                
                Button {
                    loginVM.navigate = true
                } label: {
                    Text("Continue without an account")
                }
                .padding(.vertical, 10)
                .padding(.bottom)
            }
        }
    }
    
    func registerTable() -> some View {
        VStack {
            ZStack(alignment: .top) {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            loginVM.registering = false
                            loginVM.failText = " "
                        }
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .padding()
                }
                
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                        TextField("", text: $loginVM.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.bottom)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                        TextField("", text: $loginVM.username)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.bottom)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                        SecureField("", text: $loginVM.password1)
                            .textContentType(.password)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.bottom)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                        SecureField("", text: $loginVM.password2)
                            .textContentType(.password)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .onSubmit {
                                if !(!loginVM.registerValid || loginVM.failed || loginVM.loading) {
                                    loginVM.register()
                                }
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
            }
            
            Button {
                loginVM.register()
            } label: {
                HStack {
                    Spacer()
                    if loginVM.loading {
                        ProgressView()
                            .tint(.white)
                    } else if loginVM.failed {
                        Image(systemName: "xmark")
                    } else {
                        Text("Register")
                    }
                    Spacer()
                }
                .padding(10)
                .background(loginVM.failed ? .red : Color("secondAccentColor"))
                .cornerRadius(10)
                .padding(.horizontal)
                .font(.headline)
                .opacity(loginVM.registerValid ? 1 : 0.7)
                .padding(.bottom)
            }
            .disabled(!loginVM.registerValid || loginVM.failed || loginVM.loading)
            .padding(.top, 20)
            .padding(.bottom)
        }
        .frame(width: UIScreen.main.bounds.width * 0.8)
        .background(.black.opacity(0.75))
        .cornerRadius(20)
        .foregroundStyle(.white)
        .onDisappear() {
            loginVM.username = ""
            loginVM.email = ""
            loginVM.password1 = ""
            loginVM.password2 = ""
        }
        .animation(.easeInOut(duration: 0.3), value: loginVM.registerValid)
        .padding(.bottom)
    }
    
    func loginTable() -> some View {
        VStack {
            ZStack(alignment: .top) {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            loginVM.registering = false
                            loginVM.failText = " "
                        }
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .padding()
                }
                
                VStack(spacing: 15) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                        TextField("", text: $loginVM.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.bottom)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                        SecureField("", text: $loginVM.password1)
                            .textContentType(.password)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .onSubmit {
                                if !(!loginVM.loginValid || loginVM.failed || loginVM.loading) {
                                    loginVM.login()
                                }
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
            }
            
            Button {
                loginVM.login()
            } label: {
                HStack {
                    Spacer()
                    if loginVM.loading {
                        ProgressView()
                            .tint(.white)
                    } else if loginVM.failed {
                        Image(systemName: "xmark")
                    } else {
                        Text("Log in")
                    }
                    Spacer()
                }
                .padding(10)
                .background(loginVM.failed ? .red : .accent)
                .cornerRadius(10)
                .padding(.horizontal)
                .font(.headline)
                .opacity(loginVM.loginValid ? 1 : 0.7)
                
            }
            .disabled(!loginVM.loginValid || loginVM.failed || loginVM.loading)
            .padding(.top, 30)
            .padding(.bottom)
        }
        .frame(width: UIScreen.main.bounds.width * 0.8)
        .background(.black.opacity(0.75))
        .cornerRadius(20)
        .foregroundStyle(.white)
        .onDisappear() {
            loginVM.email = ""
            loginVM.password1 = ""
        }
        .animation(.easeInOut(duration: 0.3), value: loginVM.loginValid)
        .padding(.bottom)
    }
}

#Preview {
    var vM = BindingPageViewModel()
    LoginPage(vM: vM, loginVM: LoginPageViewModel(vM: vM))
}
