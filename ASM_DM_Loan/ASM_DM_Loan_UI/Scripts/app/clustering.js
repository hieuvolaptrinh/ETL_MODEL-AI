/**
 * Clustering Application
 * Quản lý phân nhóm khách hàng
 */
function clusteringApp() {
    return {
        loading: false,
        formData: {
            gender: '',
            ageGroup: '',
            creditScore: 700,
            income: 6000,
            loanAmount: 200000,
            propertyValue: 250000,
            ltv: 80,
            dti: 35
        },
        clusterResult: null,
        similarCustomers: [],
        allClusters: [],

        init() {
            this.loadAllClusters();
        },

        async predictCluster() {
            this.loading = true;
            try {
                const input = {
                    Gender: this.formData.gender,
                    AgeGroup: this.formData.ageGroup,
                    CreditScore: parseFloat(this.formData.creditScore),
                    Income: parseFloat(this.formData.income),
                    LoanAmount: parseFloat(this.formData.loanAmount),
                    PropertyValue: parseFloat(this.formData.propertyValue),
                    LTV: parseFloat(this.formData.ltv),
                    DTI: parseFloat(this.formData.dti)
                };

                // Predict cluster
                const clusterResponse = await fetch('/api/clustering/predict', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(input)
                });

                if (!clusterResponse.ok) throw new Error('Cluster prediction failed');
                this.clusterResult = await clusterResponse.json();

                // Find similar customers
                const similarResponse = await fetch('/api/clustering/similar-customers?top=10', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(input)
                });

                if (similarResponse.ok) {
                    this.similarCustomers = await similarResponse.json();
                }

            } catch (error) {
                console.error('Error:', error);
                alert('Có lỗi xảy ra: ' + error.message);
            } finally {
                this.loading = false;
            }
        },

        async loadAllClusters() {
            try {
                const response = await fetch('/api/clustering/profiles');
                if (response.ok) {
                    this.allClusters = await response.json();
                }
            } catch (error) {
                console.error('Error loading clusters:', error);
            }
        }
    }
}
