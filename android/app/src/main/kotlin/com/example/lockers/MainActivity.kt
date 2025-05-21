package com.example.lockers

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.provider.Settings
import android.content.Context
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.lockers/device_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSerialNumber" -> {
                    try {
                        var serial = "Unknown"
                        
                        // Método 1: Usando Build.SERIAL (método mais confiável para o número de série)
                        @Suppress("DEPRECATION")
                        if (Build.SERIAL != "unknown" && Build.SERIAL.isNotEmpty()) {
                            serial = Build.SERIAL
                        }
                        
                        // Método 2: Usando getprop ro.serialno
                        if (serial == "Unknown") {
                            try {
                                val process = Runtime.getRuntime().exec("getprop ro.serialno")
                                val reader = BufferedReader(InputStreamReader(process.inputStream))
                                val roSerial = reader.readLine()
                                if (roSerial != null && roSerial.isNotEmpty() && roSerial != "unknown") {
                                    serial = roSerial
                                }
                            } catch (e: Exception) {
                                // Ignora erro e tenta próximo método
                            }
                        }
                        
                        // Método 3: Usando Build.getSerial()
                        if (serial == "Unknown" && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            try {
                                val buildSerial = Build.getSerial()
                                if (buildSerial != "unknown" && buildSerial.isNotEmpty()) {
                                    serial = buildSerial
                                }
                            } catch (e: Exception) {
                                // Ignora erro
                            }
                        }

                        println("Número de série obtido: $serial") // Debug
                        result.success(serial)
                    } catch (e: Exception) {
                        println("Erro ao obter número de série: ${e.message}") // Debug
                        result.error("UNAVAILABLE", "Número de série não disponível: ${e.message}", null)
                    }
                }
                "getAndroidId" -> {
                    try {
                        val androidId = Settings.Secure.getString(applicationContext.contentResolver, Settings.Secure.ANDROID_ID)
                        println("ANDROID_ID obtido: $androidId") // Debug
                        result.success(androidId)
                    } catch (e: Exception) {
                        println("Erro ao obter ANDROID_ID: ${e.message}") // Debug
                        result.error("UNAVAILABLE", "ANDROID_ID não disponível: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
} 