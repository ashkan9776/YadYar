package com.ahoura.yadyar.billing

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import io.flutter.plugin.common.MethodChannel
import ir.cafebazaar.poolakey.Payment
import ir.cafebazaar.poolakey.callback.PurchaseCallback
import ir.cafebazaar.poolakey.request.PurchaseRequest
import java.security.InvalidParameterException

/**
 * اکتیویتی میزبان جریان خرید بازار.
 *
 * Poolakey برای شروع جریان خرید به activityResultRegistry نیاز دارد که فقط در
 * ComponentActivity موجود است؛ FlutterActivity این نیست. این اکتیویتی شفاف
 * فقط برای میزبانی نتیجه‌ی خرید باز و بسته می‌شود.
 * (اقتباس از flutter_poolakey رسمی بازار)
 */
class PaymentActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val callback: PurchaseCallback.() -> Unit = {
            purchaseSucceed {
                result.success(it.toPurchaseMap())
                finish()
            }
            purchaseCanceled {
                result.error("PURCHASE_CANCELLED", "Purchase flow has been canceled", null)
                finish()
            }
            purchaseFailed {
                result.error("PURCHASE_FAILED", "Purchase flow has been failed", null)
                finish()
            }
            purchaseFlowBegan {
                // Nothing
            }
            failedToBeginFlow {
                result.error("FAILED_TO_BEGIN_FLOW", it.toString(), null)
                finish()
            }
        }
        when (command) {
            Command.Purchase -> purchaseProduct(callback)
            Command.Subscribe -> subscribeProduct(callback)
            else -> throw InvalidParameterException("Undefined command: $command")
        }
    }

    private fun purchaseProduct(callback: PurchaseCallback.() -> Unit) {
        payment.purchaseProduct(
            activityResultRegistry,
            PurchaseRequest(productId, payload, dynamicPriceToken),
            callback,
        )
    }

    private fun subscribeProduct(callback: PurchaseCallback.() -> Unit) {
        payment.subscribeProduct(
            activityResultRegistry,
            PurchaseRequest(productId, payload, dynamicPriceToken),
            callback,
        )
    }

    companion object {
        private lateinit var command: Command
        private lateinit var productId: String
        private lateinit var payment: Payment
        private lateinit var result: MethodChannel.Result
        private var payload: String? = null

        // توکن تخفیف پویا (JWT امضاشده سمت سرور) — برای آینده؛ فعلاً null.
        private var dynamicPriceToken: String? = null

        @JvmStatic
        fun start(
            activity: Activity,
            command: Command,
            productId: String,
            payment: Payment,
            result: MethodChannel.Result,
            payload: String?,
            dynamicPriceToken: String?,
        ) {
            val intent = Intent(activity, PaymentActivity::class.java)
            PaymentActivity.command = command
            PaymentActivity.productId = productId
            PaymentActivity.payment = payment
            PaymentActivity.result = result
            PaymentActivity.payload = payload
            PaymentActivity.dynamicPriceToken = dynamicPriceToken
            activity.startActivity(intent)
        }
    }

    enum class Command {
        Purchase,
        Subscribe,
    }
}
