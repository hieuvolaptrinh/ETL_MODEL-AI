/**
 * loan-utils.js
 * Thư viện tiện ích dùng chung để tính toán tài chính khoản vay.
 * Tất cả logic tài chính nên được đặt ở đây để tái sử dụng.
 */

const LoanUtils = (() => {

    // =============================================
    // DATA: Loan Package Definitions
    // Thêm / sửa gói vay tại đây
    // =============================================
    const LOAN_PACKAGES = {
        home: [
            {
                id: 'h1',
                name: 'Gói An Cư Lập Nghiệp',
                rateDisplay: '7.5%/năm',
                annualRate: 0.075,
                termYears: 30,
                termDisplay: 'Lên đến 30 năm',
                desc: 'Ưu đãi cố định lãi suất 2 năm đầu. Phù hợp mua nhà lần đầu.',
                defaultAmount: 150000,
                icon: 'fa-house-chimney'
            },
            {
                id: 'h2',
                name: 'Gói Vay Xây Sửa Nhà',
                rateDisplay: '8.2%/năm',
                annualRate: 0.082,
                termYears: 15,
                termDisplay: 'Lên đến 15 năm',
                desc: 'Giải ngân linh hoạt theo tiến độ thi công. Phù hợp xây dựng/sửa chữa.',
                defaultAmount: 50000,
                icon: 'fa-hammer'
            }
        ],
        car: [
            {
                id: 'c1',
                name: 'Gói Xe Mới Lăn Bánh',
                rateDisplay: '6.9%/năm',
                annualRate: 0.069,
                termYears: 7,
                termDisplay: 'Tối đa 7 năm',
                desc: 'Hỗ trợ vay đến 85% giá trị xe mới xuất xưởng.',
                defaultAmount: 40000,
                icon: 'fa-car'
            },
            {
                id: 'c2',
                name: 'Gói Xe Cũ Linh Hoạt',
                rateDisplay: '8.5%/năm',
                annualRate: 0.085,
                termYears: 5,
                termDisplay: 'Tối đa 5 năm',
                desc: 'Dành cho xe đã qua sử dụng dưới 5 năm tuổi.',
                defaultAmount: 20000,
                icon: 'fa-car-side'
            }
        ],
        business: [
            {
                id: 'b1',
                name: 'Gói Khởi Nghiệp Nhanh',
                rateDisplay: '7.9%/năm',
                annualRate: 0.079,
                termYears: 10,
                termDisplay: 'Tối đa 10 năm',
                desc: 'Không cần thế chấp 100%. Dành cho doanh nghiệp mới thành lập.',
                defaultAmount: 80000,
                icon: 'fa-rocket'
            },
            {
                id: 'b2',
                name: 'Gói Mở Rộng Quy Mô',
                rateDisplay: '6.5%/năm',
                annualRate: 0.065,
                termYears: 5,
                termDisplay: 'Tối đa 5 năm',
                desc: 'Lãi suất ưu đãi dành cho doanh nghiệp có doanh thu ổn định > 2 năm.',
                defaultAmount: 200000,
                icon: 'fa-chart-line'
            }
        ],
        personal: [
            {
                id: 'p1',
                name: 'Gói Tiêu Dùng Siêu Tốc',
                rateDisplay: '12%/năm',
                annualRate: 0.12,
                termYears: 3,
                termDisplay: 'Tối đa 3 năm',
                desc: 'Duyệt hồ sơ trong 24h, không cần thế chấp tài sản.',
                defaultAmount: 5000,
                icon: 'fa-bolt'
            },
            {
                id: 'p2',
                name: 'Gói Thẻ Tín Dụng Hạn Mức',
                rateDisplay: '0% tháng đầu',
                annualRate: 0.18,   // 18%/year after promo
                termYears: 1,       // Revolving, 1 year cycle
                termDisplay: 'Linh hoạt',
                desc: 'Miễn lãi tháng đầu. Rút tiền mặt và quẹt thẻ linh hoạt.',
                defaultAmount: 2000,
                icon: 'fa-credit-card'
            }
        ]
    };

    // =============================================
    // FUNCTION: Get packages by purpose
    // =============================================
    function getPackagesByPurpose(purpose) {
        return LOAN_PACKAGES[purpose] || [];
    }

    // =============================================
    // FUNCTION: Get a single package by ID
    // =============================================
    function getPackageById(id) {
        for (const category of Object.values(LOAN_PACKAGES)) {
            const pkg = category.find(p => p.id === id);
            if (pkg) return pkg;
        }
        return null;
    }

    // =============================================
    // FUNCTION: Calculate Monthly Payment (PMT formula)
    // @param principal   - Số tiền vay (USD)
    // @param annualRate  - Lãi suất hàng năm (dạng thập phân, vd: 0.075)
    // @param termYears   - Kỳ hạn tính bằng năm
    // @returns           - Số tiền trả hàng tháng (USD)
    // =============================================
    function calculateMonthlyPayment(principal, annualRate, termYears) {
        if (!principal || principal <= 0) return 0;
        if (!termYears || termYears <= 0) return 0;
        
        const monthlyRate = annualRate / 12;
        const numPayments = termYears * 12;

        // Nếu lãi suất = 0, chia đều
        if (monthlyRate === 0) {
            return Math.round(principal / numPayments);
        }
        
        const powerTerm = Math.pow(1 + monthlyRate, numPayments);
        const payment = principal * (monthlyRate * powerTerm) / (powerTerm - 1);
        
        return isNaN(payment) || !isFinite(payment) ? 0 : Math.round(payment);
    }

    // =============================================
    // FUNCTION: Get monthly payment for the currently selected package
    // @param loanAmount    - Số tiền vay
    // @param selectedPkgId - ID gói vay đang được chọn
    // @param fallbackPurpose - Mục đích vay (dùng gói đầu tiên nếu chưa chọn gói)
    // @returns             - { payment, annualRate, termYears }
    // =============================================
    function getMonthlyPaymentForSelection(loanAmount, selectedPkgId, fallbackPurpose) {
        let pkg = null;
        
        if (selectedPkgId) {
            pkg = getPackageById(selectedPkgId);
        }
        
        // Fallback: dùng gói đầu tiên của mục đích, hoặc default 30 năm 5%
        if (!pkg && fallbackPurpose) {
            const packages = getPackagesByPurpose(fallbackPurpose);
            pkg = packages[0] || null;
        }

        if (pkg) {
            return {
                payment: calculateMonthlyPayment(loanAmount, pkg.annualRate, pkg.termYears),
                annualRate: pkg.annualRate,
                termYears: pkg.termYears,
                rateDisplay: pkg.rateDisplay,
                termDisplay: pkg.termDisplay
            };
        }

        // Hard default (khi chưa chọn gì)
        const defaultRate = 0.08;
        const defaultTerm = 20;
        return {
            payment: calculateMonthlyPayment(loanAmount, defaultRate, defaultTerm),
            annualRate: defaultRate,
            termYears: defaultTerm,
            rateDisplay: '8.0%/năm',
            termDisplay: '20 năm (mặc định)'
        };
    }

    // =============================================
    // FUNCTION: Calculate LTV (Loan-To-Value)
    // =============================================
    function calculateLTV(loanAmount, propertyValue) {
        if (!propertyValue || propertyValue === 0) return 0;
        const ltv = (loanAmount / propertyValue) * 100;
        return isNaN(ltv) || !isFinite(ltv) ? 0 : ltv;
    }

    // =============================================
    // FUNCTION: Calculate DTI (Debt-To-Income)
    // =============================================
    function calculateDTI(monthlyPayment, monthlyIncome) {
        if (!monthlyIncome || monthlyIncome === 0) return 0;
        const dti = (monthlyPayment / monthlyIncome) * 100;
        return isNaN(dti) || !isFinite(dti) ? 0 : dti;
    }

    // =============================================
    // FUNCTION: Get age group string from numeric age
    // =============================================
    function getAgeGroup(age) {
        if (!age || age < 18) return '';
        if (age < 25) return '<25';
        if (age <= 34) return '25-34';
        if (age <= 44) return '35-44';
        if (age <= 54) return '45-54';
        if (age <= 64) return '55-64';
        if (age <= 74) return '65-74';
        return '>74';
    }

    // =============================================
    // FUNCTION: Credit score label & color
    // =============================================
    function getCreditScoreInfo(score) {
        if (score >= 800) return { label: 'Xuất sắc', color: 'text-green-600', badge: 'bg-green-100 text-green-800' };
        if (score >= 740) return { label: 'Rất tốt',  color: 'text-blue-600',  badge: 'bg-blue-100 text-blue-800' };
        if (score >= 670) return { label: 'Tốt',      color: 'text-yellow-600', badge: 'bg-yellow-100 text-yellow-800' };
        if (score >= 580) return { label: 'Trung bình', color: 'text-orange-600', badge: 'bg-orange-100 text-orange-800' };
        return                    { label: 'Kém',      color: 'text-red-600',   badge: 'bg-red-100 text-red-800' };
    }

    // =============================================
    // Public API
    // =============================================
    return {
        LOAN_PACKAGES,
        getPackagesByPurpose,
        getPackageById,
        calculateMonthlyPayment,
        getMonthlyPaymentForSelection,
        calculateLTV,
        calculateDTI,
        getAgeGroup,
        getCreditScoreInfo
    };
})();
