package com.ahoura.yadyar.billing

import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import ir.cafebazaar.poolakey.Connection
import ir.cafebazaar.poolakey.ConnectionState
import ir.cafebazaar.poolakey.Payment
import ir.cafebazaar.poolakey.config.PaymentConfiguration
import ir.cafebazaar.poolakey.config.SecurityCheck

/**
 * پل پرداخت درون‌برنامه‌ای کافه‌بازار (Poolakey) برای سمت فلاتر.
 *
 * چرا پلاگین pub استفاده نمی‌شود؟ flutter_poolakey در build.gradle خود از
 * jcenter() استفاده می‌کند که در Gradle 9 حذف شده و با AGP 9 ناسازگار است؛
 * این پل همان API را با وابستگی مستقیم به AAR پولکی فراهم می‌کند.
 * (ساختار متدها عیناً از سورس flutter_poolakey رسمی بازار اقتباس شده)
 */
object PoolakeyBridge {
    private const val channelName = "com.ahoura.yadyar/poolakey"

    private var payment: Payment? = null
    private var paymentConnection: Connection? = null

    fun attach(activity: Activity, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "connect" -> connect(
                        activity,
                        call.argument<String>("in_app_billing_key"),
                        result,
                    )

                    "purchase" -> startPurchase(
                        activity = activity,
                        command = PaymentActivity.Command.Purchase,
                        productId = call.argument<String>("product_id")!!,
                        payload = call.argument<String>("payload"),
                        dynamicPriceToken = call.argument<String>("dynamicPriceToken"),
                        result = result,
                    )

                    "get_all_purchased_products" -> getAllPurchasedProducts(result)

                    "disconnect" -> {
                        paymentConnection?.disconnect()
                        paymentConnection = null
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun connect(activity: Activity, rsaKey: String?, result: MethodChannel.Result) {
        val securityCheck = if (!rsaKey.isNullOrEmpty()) {
            SecurityCheck.Enable(rsaPublicKey = rsaKey)
        } else {
            SecurityCheck.Disable
        }
        val payment =
            Payment(context = activity, config = PaymentConfiguration(localSecurityCheck = securityCheck))
        this.payment = payment

        paymentConnection = payment.connect {
            connectionSucceed {
                result.success(true)
            }
            connectionFailed {
                // معمولاً یعنی بازار نصب نیست یا در دسترس نیست.
                result.error("CONNECTION_FAILED", it.toString(), null)
            }
            disconnected {
                // اتصال در طول عمر اپ قطع شده؛ سمت دارت در صورت نیاز دوباره connect می‌زند.
            }
        }
    }

    private fun startPurchase(
        activity: Activity,
        command: PaymentActivity.Command,
        productId: String,
        payload: String?,
        dynamicPriceToken: String?,
        result: MethodChannel.Result,
    ) {
        val connection = paymentConnection
        val payment = payment
        if (connection == null || payment == null ||
            connection.getState() != ConnectionState.Connected
        ) {
            result.error("NOT_CONNECTED", "Connect to Bazaar before purchasing", null)
            return
        }

        PaymentActivity.start(activity, command, productId, payment, result, payload, dynamicPriceToken)
    }

    private fun getAllPurchasedProducts(result: MethodChannel.Result) {
        val connection = paymentConnection
        val payment = payment
        if (connection == null || payment == null ||
            connection.getState() != ConnectionState.Connected
        ) {
            result.error("NOT_CONNECTED", "Connect to Bazaar before querying purchases", null)
            return
        }

        payment.getPurchasedProducts {
            querySucceed { purchasedItems ->
                result.success(purchasedItems.map { it.toPurchaseMap() })
            }
            queryFailed {
                // مثلاً وقتی کاربر وارد حساب بازار خود نشده باشد.
                result.error("QUERY_PURCHASED_PRODUCT_FAILED", it.toString(), null)
            }
        }
    }
}
