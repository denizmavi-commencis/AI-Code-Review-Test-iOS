package com.example.seat

// Bu interface app module'de implement edilecek ve baggage service'e erişim sağlayacak
interface IBaggageServiceProvider {
    fun addBaggageForSeat(passengerId: String, weight: Double)
}

class SeatManager(private val baggageServiceProvider: IBaggageServiceProvider) {
    
    fun selectSeat(seatNumber: String, passengerId: String) {
        println("SeatManager: Seat $seatNumber selected for passenger: $passengerId")
        
        // Koltuk seçimi yapıldığında baggage ekleme işlemi
        // App module vasıtası ile baggage module'deki methoda erişiyor
        baggageServiceProvider.addBaggageForSeat(passengerId, 23.5)
        
        println("SeatManager: Baggage added through app module")
    }
    
    fun getSeatMap(): List<String> {
        // Boş method - sadece bağımlılık gösterimi için
        println("SeatManager: getSeatMap method called")
        return listOf("1A", "1B", "1C", "2A", "2B", "2C")
    }
    
    fun isSeatAvailable(seatNumber: String): Boolean {
        // Boş method - sadece bağımlılık gösterimi için
        println("SeatManager: isSeatAvailable method called for seat: $seatNumber")
        return true
    }
}
