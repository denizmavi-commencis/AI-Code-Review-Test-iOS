package com.example.passenger

class PassengerManager {
    
    private val navigationService = PassengerNavigationService()
    
    fun addPassenger(name: String, age: Int) {
        // Boş method - sadece bağımlılık gösterimi için
        println("PassengerManager: addPassenger method called for $name, age: $age")
    }
    
    fun removePassenger(passengerId: String) {
        // Boş method - sadece bağımlılık gösterimi için
        println("PassengerManager: removePassenger method called for ID: $passengerId")
    }
    
    fun getPassengerNavigation(): PassengerNavigationService {
        return navigationService
    }
}
