package com.example.flightlist

import com.example.passenger.PassengerManager

class FlightListManager {
    
    private val passengerManager = PassengerManager()
    
    fun selectFlight(flightId: String) {
        // Flight seçildiğinde passenger module'deki navigasyon methodunu çağırıyor
        println("FlightListManager: Flight selected with ID: $flightId")
        
        // Passenger module'e erişip navigasyon methodunu çağırıyor
        val navigationService = passengerManager.getPassengerNavigation()
        navigationService.navigateToPassengerDetails()
        
        println("FlightListManager: Navigated to passenger details")
    }
    
    fun showFlightDetails(flightId: String) {
        println("FlightListManager: Showing flight details for ID: $flightId")
        
        // Passenger module'e erişip başka bir navigasyon methodunu çağırıyor
        val navigationService = passengerManager.getPassengerNavigation()
        navigationService.navigateToSeatSelection()
    }
    
    fun getFlightList(): List<String> {
        // Boş method - sadece bağımlılık gösterimi için
        println("FlightListManager: getFlightList method called")
        return listOf("Flight1", "Flight2", "Flight3")
    }
}
