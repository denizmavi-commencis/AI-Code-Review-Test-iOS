package com.example.baggage

class BaggageService {
    
    fun addBaggage(passengerId: String, weight: Double) {
        // Boş method - sadece bağımlılık gösterimi için (seat module bu methoda erişecek)
        println("BaggageService: addBaggage method called for passenger: $passengerId, weight: $weight")
    }
    
    fun removeBaggage(baggageId: String) {
        // Boş method - sadece bağımlılık gösterimi için
        println("BaggageService: removeBaggage method called for baggage ID: $baggageId")
    }
    
    fun calculateBaggageFee(weight: Double): Double {
        // Boş method - sadece bağımlılık gösterimi için
        println("BaggageService: calculateBaggageFee method called for weight: $weight")
        return weight * 10.0 // Örnek hesaplama
    }
    
    fun getBaggageList(passengerId: String): List<String> {
        // Boş method - sadece bağımlılık gösterimi için
        println("BaggageService: getBaggageList method called for passenger: $passengerId")
        return listOf("Baggage1", "Baggage2")
    }
}
