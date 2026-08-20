package com.oxpay.o7lite.utils

import android.annotation.SuppressLint
import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import androidx.recyclerview.widget.RecyclerView.Adapter
import com.oxpay.o7lite.R
import com.oxpay.o7lite.entity.TransactionItem
import com.oxpay.o7lite.enums.TransactionType
import com.oxpay.o7lite.utils.Utils.toDollars

class TransactionSummaryAdapter(
    private val context: Context,
    private val transactionList: List<TransactionItem>?
) : Adapter<TransactionSummaryAdapter.ViewHolder>() {
    class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val ivLogo: ImageView = view.findViewById(R.id.ivPaymentLogo)
        val tvTxnType: TextView = view.findViewById(R.id.tvTxnType)
        val tvTxnTime: TextView = view.findViewById(R.id.tvTxnTime)
        val tvTxnAmount: TextView = view.findViewById(R.id.tvTxnAmount)
    }

    override fun onCreateViewHolder(group: ViewGroup, position: Int): ViewHolder {
        val view = LayoutInflater.from(context).inflate(R.layout.item_txn_list_castle, group, false)
        return ViewHolder(view)
    }

    override fun getItemCount(): Int {
        return transactionList?.size ?: 0
    }

    @SuppressLint("SetTextI18n")
    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val transaction = transactionList?.get(position)
        holder.ivLogo.setImageResource(Utils.getItemStatus(transaction?.responseCode))
        holder.tvTxnAmount.text = transaction?.currency + " " + transaction?.totalAmount.toDollars()
        try {
            holder.tvTxnTime.text = Utils.convertHHMM(transaction?.gatewayResponseDate)
        } catch (e: Exception) {
            holder.tvTxnTime.text = ""
            LogUtil.e("TransactionSummaryAdapter", "onBindViewHolder: ${e.message}")
        }

        when (transaction?.type) {
            TransactionType.PREAUTH,
            TransactionType.SALES,
            TransactionType.SALE,
            TransactionType.QUICK_PAY,
            TransactionType.UNIFIED_ORDER,
            TransactionType.SUBMIT_QUICK_PAY -> {
                holder.tvTxnType.text = TransactionType.SALE
            }

            TransactionType.VOID,
            TransactionType.REVERSE,
            TransactionType.EWALLET_VOID -> {
                holder.tvTxnType.text = TransactionType.VOIDED
                holder.tvTxnAmount.text = transaction.currency + " -" + transaction.totalAmount.toDollars()
            }

            TransactionType.REFUND -> {
                holder.tvTxnType.text = TransactionType.REFUND
                holder.tvTxnAmount.text = transaction.currency + " -" + transaction.totalAmount.toDollars()
            }

            else -> {
                holder.tvTxnType.text = transaction?.type
            }
        }
    }
}
