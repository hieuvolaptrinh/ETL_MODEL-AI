/**
 * Prediction Application (Decision Tree)
 * Quản lý dự đoán khoản vay bằng Decision Tree
 */
function predictionApp() {
    return {
        loading: false,
        error: null,
        result: null,
        form: {
            CreditScore: 750,
            Income: 5000,
            LoanAmount: 200000,
            PropertyValue: 300000,
            LTV: 80,
            DTI: 35,
            LoanPurpose: 'Home'
        },

        async predict() {
            try {
                this.loading = true;
                this.error = null;
                this.result = null;

                const response = await fetch('/api/decision-tree/predict', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(this.form)
                });

                if (!response.ok) {
                    throw new Error('Prediction failed');
                }

                this.result = await response.json();
            } catch (err) {
                this.error = err.message;
                console.error('Error predicting:', err);
            } finally {
                this.loading = false;
            }
        }
    }
}
