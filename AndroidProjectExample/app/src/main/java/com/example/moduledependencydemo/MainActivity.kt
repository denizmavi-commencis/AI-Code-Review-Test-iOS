package com.example.moduledependencydemo

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.example.baggage.BaggageService
import com.example.seat.IBaggageServiceProvider
import com.example.seat.SeatManager

class MainActivity : AppCompatActivity() {
    
    // Baggage Service Provider Implementation - Seat module için
    private class BaggageServiceProvider(private val baggageService: BaggageService) : IBaggageServiceProvider {
        override fun addBaggageForSeat(passengerId: String, weight: Double) {
            // App module vasıtası ile baggage module'deki methoda erişim
            baggageService.addBaggage(passengerId, weight)
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        // Tüm modülleri test etmek için bağımlılıkları gösteriyoruz
        demonstrateModuleDependencies()
    }
    
    private fun demonstrateModuleDependencies() {
        println("=== SEAT -> APP -> BAGGAGE MODULE DEPENDENCY DEMONSTRATION ===")
        
        // Seat Module -> App Module -> Baggage Module bağımlılığı
        println("\nSeat Module -> App Module -> Baggage Module Dependencies:")
        val baggageService = BaggageService()
        val baggageServiceProvider = BaggageServiceProvider(baggageService)
        val seatManager = SeatManager(baggageServiceProvider)
        
        // Koltuk seçimi yapıldığında baggage service'e erişim gösterimi
        seatManager.selectSeat("1A", "passenger123")
        seatManager.selectSeat("2B", "passenger456")
        
        // Diğer seat ve baggage methodları
        println("\nOther Seat and Baggage Methods:")
        val seatMap = seatManager.getSeatMap()
        val isAvailable = seatManager.isSeatAvailable("1B")
        val baggageList = baggageService.getBaggageList("passenger123")
        val fee = baggageService.calculateBaggageFee(25.0)
        
        println("Seat Map: $seatMap")
        println("Seat 1B Available: $isAvailable")
        println("Baggage List: $baggageList")
        println("Baggage Fee: $fee")
        
        println("\n=== SEAT -> APP -> BAGGAGE DEPENDENCY DEMONSTRATED ===")
        println("Note: Other module dependencies (login, home, flightlist, passenger) work independently")
    }
}
