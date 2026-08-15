package com.ahoura.yadyar

import com.ahoura.yadyar.billing.PoolakeyBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // پل پرداخت درون‌برنامه‌ای کافه‌بازار.
        PoolakeyBridge.attach(this, flutterEngine)
    }
}
