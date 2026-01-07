package com.example.loginapi

interface ILoginService {
    fun login(username: String, password: String)
    fun logout()
    fun isLoggedIn(): Boolean
}
