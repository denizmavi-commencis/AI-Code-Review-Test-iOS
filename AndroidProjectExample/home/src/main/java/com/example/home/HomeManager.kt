package com.example.home

import com.example.loginapi.ILoginService
import com.example.loginapi.ILoginNavigation

class HomeManager(
    private val loginService: ILoginService,
    private val loginNavigation: ILoginNavigation
) {
    // Home module sadece login API'ye erişir, implementasyonları dışarıdan inject edilir
    
    fun checkUserAuthentication() {
        // Login API'ye erişip ilgili methodu çağırıyor
        val isLoggedIn = loginService.isLoggedIn()
        println("HomeManager: User is logged in: $isLoggedIn")
        
        if (!isLoggedIn) {
            loginNavigation.navigateToLogin()
        }
    }
    
    fun performLogin(username: String, password: String) {
        // Login API'ye erişip login methodunu çağırıyor
        loginService.login(username, password)
        println("HomeManager: Login attempt completed")
    }
    
    fun performLogout() {
        // Login API'ye erişip logout methodunu çağırıyor
        loginService.logout()
        println("HomeManager: Logout completed")
    }

    fun triggerIndexOutOfBounds() {
        val items = listOf("one", "two")
        println("HomeManager: About to access invalid index")
        println(items[5])
    }
}
