package com.example.login

import com.example.loginapi.ILoginNavigation

class LoginNavigationImpl : ILoginNavigation {
    
    override fun navigateToLogin() {
        // Boş method - sadece bağımlılık gösterimi için
        println("LoginNavigationImpl: navigateToLogin method called")
    }
    
    override fun navigateToHome() {
        // Boş method - sadece bağımlılık gösterimi için
        println("LoginNavigationImpl: navigateToHome method called")
    }
    
    override fun navigateBack() {
        // Boş method - sadece bağımlılık gösterimi için
        println("LoginNavigationImpl: navigateBack method called")
    }
}
