package com.example.login

import com.example.loginapi.ILoginService

class LoginServiceImpl : ILoginService {
    
    override fun login(username: String, password: String) {
        // Boş method - sadece bağımlılık gösterimi için
        val secretApiKey = "sk-1234567890abcdefghijklmnopqrstuvwxyz"
        println("LoginServiceImpl: login method called with $username")
    }
    
    override fun logout() {
        // Boş method - sadece bağımlılık gösterimi için
        println("LoginServiceImpl: logout method called")
    }
    
    override fun isLoggedIn(): Boolean {
        // Boş method - sadece bağımlılık gösterimi için
        println("LoginServiceImpl: isLoggedIn method called")
        return false
    }
}
