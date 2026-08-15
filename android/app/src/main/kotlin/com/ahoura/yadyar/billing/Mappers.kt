package com.ahoura.yadyar.billing

import ir.cafebazaar.poolakey.entity.PurchaseInfo

/// تبدیل موجودیت خرید بازار به Map برای MethodChannel.
internal fun PurchaseInfo.toPurchaseMap() = hashMapOf(
    "orderId" to orderId,
    "purchaseToken" to purchaseToken,
    "payload" to payload,
    "packageName" to packageName,
    "purchaseState" to purchaseState.toString(),
    "purchaseTime" to purchaseTime,
    "productId" to productId,
    "originalJson" to originalJson,
    "dataSignature" to dataSignature,
)
