/**
 * Prediction Application (Decision Tree)
 * Ứng dụng dự đoán khoản vay bằng Decision Tree
 */
function predictionApp() {
    return {
        mode: 'simple', // simple, advanced, compare
        loading: false,
        error: null,
        result: null,
        showCreditEstimator: false,
        
        formData: {
            gender: '',
            age: null,
            loanPurpose: '',
            creditScore: 750,
            income: 5000,
            loanAmount: 200000,
            propertyValue: 300000
        },

        estimator: {
            hasLoan: false,
            hasCreditCard: false,
            payOnTime: false,
            hasAssets: false,
            stableIncome: false
        },
        selectedPackage: null,

        // Computed properties
        get calculatedLTV() {
            return LoanUtils.calculateLTV(this.formData.loanAmount, this.formData.propertyValue);
        },

        get activePaymentInfo() {
            return LoanUtils.getMonthlyPaymentForSelection(
                this.formData.loanAmount,
                this.selectedPackage,
                this.formData.loanPurpose
            );
        },

        get monthlyPayment() {
            return this.activePaymentInfo.payment;
        },

        get calculatedDTI() {
            return LoanUtils.calculateDTI(this.monthlyPayment, this.formData.income);
        },

        get suggestedPackages() {
            return LoanUtils.getPackagesByPurpose(this.formData.loanPurpose);
        },

        selectPackage(pkg) {
            this.selectedPackage = pkg.id;
            this.formData.loanAmount = pkg.defaultAmount;
        },

        // Credit Score Helpers — delegated to LoanUtils
        getCreditScoreColor(score) {
            return LoanUtils.getCreditScoreInfo(score).color;
        },

        getCreditScoreBadgeClass(score) {
            return LoanUtils.getCreditScoreInfo(score).badge;
        },

        getCreditScoreLabel(score) {
            return LoanUtils.getCreditScoreInfo(score).label;
        },

        getCreditScoreBadgeClass(score) {
            if (score >= 800) return 'bg-green-100 text-green-800';
            if (score >= 740) return 'bg-blue-100 text-blue-800';
            if (score >= 670) return 'bg-yellow-100 text-yellow-800';
            if (score >= 580) return 'bg-orange-100 text-orange-800';
            return 'bg-red-100 text-red-800';
        },

        getCreditScoreLabel(score) {
            if (score >= 800) return 'Xuất sắc';
            if (score >= 740) return 'Rất tốt';
            if (score >= 670) return 'Tốt';
            if (score >= 580) return 'Trung bình';
            return 'Yếu';
        },

        // Credit Score Estimator
        estimateCreditScore() {
            let score = 500; // Base score
            
            if (this.estimator.hasLoan) score += 50;
            if (this.estimator.hasCreditCard) score += 50;
            if (this.estimator.payOnTime) score += 150;
            if (this.estimator.hasAssets) score += 75;
            if (this.estimator.stableIncome) score += 75;
            
            // Cap at 900
            score = Math.min(score, 900);
            
            this.formData.creditScore = score;
            this.showCreditEstimator = false;
            
            // Show notification
            alert(`Điểm tín dụng ước tính của bạn: ${score}\n\nLưu ý: Đây chỉ là ước tính, điểm thực tế có thể khác.`);
        },

        getCalculatedAgeGroup(age) {
            return LoanUtils.getAgeGroup(age);
        },

        // Risk Meter Angle
        getRiskNeedleAngle() {
            if (!this.result) return -90; // Default position
            
            const approvalProb = this.result.ApprovalProbability;
            // Map 0-1 to -90 to 90 degrees
            return (approvalProb * 180) - 90;
        },

        getRiskCategoryColor(category) {
            if (!category) return 'text-gray-600';
            if (category.includes('LOW') || category.includes('THẤP')) return 'text-green-600';
            if (category.includes('MEDIUM') || category.includes('TRUNG BÌNH')) return 'text-yellow-600';
            if (category.includes('HIGH') || category.includes('CAO')) return 'text-red-600';
            return 'text-gray-600';
        },

        // Get AI Recommendation based on result
        getRecommendation() {
            if (!this.result) return 'Chưa có dữ liệu đánh giá';
            
            const risk = this.result.RiskCategory || '';
            const dti = this.result.DTI || this.calculatedDTI || 0;
            const ltv = this.result.LTV || this.calculatedLTV || 0;
            const creditScore = this.formData.creditScore || 0;
            const loanAmount = this.formData.loanAmount || 0;
            const propertyValue = this.formData.propertyValue || 0;
            const income = this.formData.income || 0;
            const monthlyPayment = this.monthlyPayment || 0;
            
            // HIGH RISK
            if (risk.includes('HIGH') || risk.includes('CAO')) {
                if (dti > 43 && ltv > 90) {
                    const targetPayment = income * 0.36; // 36% DTI
                    const maxLoan = propertyValue * 0.80; // 80% LTV
                    return `Rủi ro rất cao do DTI ${dti.toFixed(1)}% và LTV ${ltv.toFixed(1)}%. Để được duyệt: (1) Giảm khoản vay xuống $${maxLoan.toLocaleString()} (80% giá trị tài sản), hoặc (2) Tăng thu nhập lên $${(monthlyPayment / 0.36).toLocaleString()}/tháng, hoặc (3) Thêm người đồng vay có thu nhập ổn định.`;
                } else if (dti > 43) {
                    const targetIncome = monthlyPayment / 0.36;
                    const targetLoan = income * 0.36 * 360; // Assuming 30 year loan
                    return `Tỷ lệ nợ/thu nhập ${dti.toFixed(1)}% vượt ngưỡng 43%. Để cải thiện: (1) Tăng thu nhập lên $${targetIncome.toLocaleString()}/tháng, hoặc (2) Giảm khoản vay xuống $${targetLoan.toLocaleString()}, hoặc (3) Thanh toán hết các khoản nợ hiện tại trước khi vay.`;
                } else if (ltv > 90) {
                    const minDownPayment = propertyValue * 0.20;
                    const maxLoanAmount = propertyValue * 0.80;
                    return `Tỷ lệ cho vay ${ltv.toFixed(1)}% quá cao, rủi ro mất vốn nếu giá nhà giảm. Cần đặt cọc thêm $${minDownPayment.toLocaleString()} để đạt LTV 80%, hoặc giảm khoản vay xuống $${maxLoanAmount.toLocaleString()}.`;
                } else if (creditScore < 580) {
                    return `Điểm tín dụng ${creditScore} quá thấp (dưới 580). Để cải thiện: (1) Thanh toán đúng hạn tất cả hóa đơn trong 6-12 tháng, (2) Giảm số dư thẻ tín dụng xuống dưới 30% hạn mức, (3) Không mở thêm tài khoản tín dụng mới, (4) Kiểm tra và khiếu nại các thông tin sai trên báo cáo tín dụng.`;
                }
                return `Hồ sơ không đạt tiêu chuẩn tín dụng tối thiểu. Khuyến nghị từ chối hoặc yêu cầu người bảo lãnh có điểm tín dụng trên 700.`;
            }
            
            // MEDIUM RISK
            if (risk.includes('MEDIUM') || risk.includes('TRUNG BÌNH')) {
                const suggestions = [];
                
                if (dti > 36) {
                    const targetIncome = monthlyPayment / 0.36;
                    const extraIncome = targetIncome - income;
                    suggestions.push(`tăng thu nhập thêm $${extraIncome.toLocaleString()}/tháng (có thể bằng thu nhập phụ, tiền thuê nhà, hoặc thêm người đồng vay)`);
                }
                
                if (ltv > 80) {
                    const extraDownPayment = loanAmount - (propertyValue * 0.80);
                    suggestions.push(`đặt cọc thêm $${extraDownPayment.toLocaleString()} để đạt LTV 80%`);
                }
                
                if (creditScore < 700) {
                    const pointsNeeded = 700 - creditScore;
                    suggestions.push(`cải thiện điểm tín dụng thêm ${pointsNeeded} điểm bằng cách thanh toán đúng hạn và giảm nợ thẻ tín dụng`);
                }
                
                if (suggestions.length > 0) {
                    return `Rủi ro trung bình, có thể phê duyệt nếu: ${suggestions.join('; ')}. Nếu không thể cải thiện, ngân hàng có thể chấp nhận với lãi suất cao hơn 0.5-1% hoặc yêu cầu mua bảo hiểm khoản vay.`;
                }
                return `Rủi ro trung bình. Cân nhắc phê duyệt với lãi suất điều chỉnh tăng 0.5-1% hoặc yêu cầu bảo hiểm khoản vay để giảm rủi ro.`;
            }
            
            // LOW RISK
            if (risk.includes('LOW') || risk.includes('THẤP')) {
                if (creditScore >= 800 && dti < 30 && ltv < 70) {
                    return `Hồ sơ xuất sắc! Điểm tín dụng ${creditScore}, DTI ${dti.toFixed(1)}%, LTV ${ltv.toFixed(1)}% - tất cả đều ở mức tối ưu. Khách hàng VIP, ưu tiên phê duyệt nhanh trong 24h với lãi suất ưu đãi thấp nhất.`;
                } else if (creditScore >= 740 && dti < 36 && ltv < 80) {
                    return `Hồ sơ tốt, đáp ứng đầy đủ tiêu chuẩn tín dụng. Khả năng trả nợ cao, rủi ro thấp. Phê duyệt với lãi suất chuẩn, thời gian xử lý 2-3 ngày làm việc.`;
                }
                return `Rủi ro thấp. Khoản vay an toàn, khách hàng có khả năng trả nợ tốt. Đủ điều kiện phê duyệt với điều khoản chuẩn.`;
            }
            
            return 'Đang phân tích dữ liệu...';
        },

        // Sample Data
        fillSampleData(type) {
            if (type === 'good') {
                this.formData = {
                    gender: 'Male',
                    age: 38,
                    loanPurpose: 'home',
                    creditScore: 820,
                    income: 10000,
                    loanAmount: 250000,
                    propertyValue: 400000
                };
            } else if (type === 'bad') {
                this.formData = {
                    gender: 'Female',
                    age: 28,
                    loanPurpose: 'personal',
                    creditScore: 550,
                    income: 3000,
                    loanAmount: 300000,
                    propertyValue: 320000
                };
            }
            this.result = null;
            this.error = null;
        },

        // Prediction
        async predict() {
            try {
                this.loading = true;
                this.error = null;
                this.result = null;

                // Validate form
                if (!this.formData.gender || !this.formData.age) {
                    this.error = 'Vui lòng điền đầy đủ thông tin cá nhân (Giới tính và Tuổi)';
                    this.loading = false;
                    return;
                }

                if (this.formData.age < 18) {
                    this.error = 'Người vay phải từ 18 tuổi trở lên';
                    this.loading = false;
                    return;
                }

                if (!this.formData.propertyValue || this.formData.propertyValue === 0) {
                    this.error = 'Giá trị tài sản phải lớn hơn 0';
                    this.loading = false;
                    return;
                }

                if (!this.formData.income || this.formData.income === 0) {
                    this.error = 'Thu nhập phải lớn hơn 0';
                    this.loading = false;
                    return;
                }

                const ltv = this.calculatedLTV;
                const dti = this.calculatedDTI;

                if (isNaN(ltv) || !isFinite(ltv)) {
                    this.error = 'LTV không hợp lệ. Vui lòng kiểm tra lại số tiền vay và giá trị tài sản';
                    this.loading = false;
                    return;
                }

                if (isNaN(dti) || !isFinite(dti)) {
                    this.error = 'DTI không hợp lệ. Vui lòng kiểm tra lại thu nhập';
                    this.loading = false;
                    return;
                }

                const mappedAgeGroup = this.getCalculatedAgeGroup(this.formData.age);

                const input = {
                    Gender: this.formData.gender,
                    AgeGroup: mappedAgeGroup,
                    CreditScore: parseFloat(this.formData.creditScore),
                    Income: parseFloat(this.formData.income),
                    LoanAmount: parseFloat(this.formData.loanAmount),
                    PropertyValue: parseFloat(this.formData.propertyValue),
                    LTV: parseFloat(ltv.toFixed(2)),
                    DTI: parseFloat(dti.toFixed(2))
                };

                console.log('Sending request:', input);

                const response = await fetch('/api/decision-tree/predict', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(input)
                });

                console.log('Response status:', response.status);

                if (!response.ok) {
                    const errorText = await response.text();
                    console.error('Error response:', errorText);
                    throw new Error(`Không thể kết nối đến server (${response.status})`);
                }

                this.result = await response.json();
                console.log('Result:', this.result);

                if (this.result.PredictionResult === 'APPROVED') {
                    setTimeout(() => {
                        this.triggerConfetti();
                    }, 500);
                }

                // Scroll to results
                setTimeout(() => {
                    const resultElement = document.querySelector('[x-show="result"]');
                    if (resultElement) {
                        resultElement.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
                    }
                }, 100);

            } catch (error) {
                console.error('Error:', error);
                this.error = error.message || 'Có lỗi xảy ra, vui lòng thử lại';
            } finally {
                this.loading = false;
            }
        },

        triggerConfetti() {
            if (typeof confetti !== 'function') return;
            
            var duration = 3 * 1000;
            var animationEnd = Date.now() + duration;
            var defaults = { startVelocity: 30, spread: 360, ticks: 60, zIndex: 100 };

            function randomInRange(min, max) {
                return Math.random() * (max - min) + min;
            }

            var interval = setInterval(function() {
                var timeLeft = animationEnd - Date.now();

                if (timeLeft <= 0) {
                    return clearInterval(interval);
                }

                var particleCount = 50 * (timeLeft / duration);
                confetti(Object.assign({}, defaults, { particleCount,
                    origin: { x: randomInRange(0.1, 0.3), y: Math.random() - 0.2 }
                }));
                confetti(Object.assign({}, defaults, { particleCount,
                    origin: { x: randomInRange(0.7, 0.9), y: Math.random() - 0.2 }
                }));
            }, 250);
        }
    }
}
