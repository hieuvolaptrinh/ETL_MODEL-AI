/**
 * Logistic Regression Application
 * Dự đoán nợ xấu khách hàng và hiển thị kết quả train model
 */
function logisticApp() {
  return {
    loading: false,
    error: null,
    result: null,
    chartInstance: null,

    formData: {
      gender: "Male",
      ageGroup: "35-44",
      age: 38,
      creditScore: 680,
      income: 6500,
      loanAmount: 180000,
      propertyValue: 250000,
      ltv: 72,
      dti: 34,
      loanPurpose: "home",
      creditType: "Standard",
      loanType: "Conventional",
      rateOfInterest: 5.5,
      term: 360,
    },

    get calculatedLTV() {
      if (this.formData.propertyValue <= 0) return 0;
      return (this.formData.loanAmount / this.formData.propertyValue) * 100;
    },

    get calculatedDTI() {
      const monthlyDebt = this.formData.loanAmount / 360;
      if (this.formData.income <= 0) return 0;
      return (monthlyDebt / this.formData.income) * 100;
    },

    init() {
      this.formData.ltv = this.calculatedLTV || this.formData.ltv;
      this.formData.dti = this.calculatedDTI || this.formData.dti;
    },

    fillSample(type) {
      if (type === "good") {
        this.formData = {
          gender: "Male",
          ageGroup: "35-44",
          age: 38,
          creditScore: 810,
          income: 15000,
          loanAmount: 180000,
          propertyValue: 350000,
          ltv: 51,
          dti: 22,
          loanPurpose: "home",
          creditType: "Standard",
          loanType: "Conventional",
          rateOfInterest: 4.5,
          term: 360,
        };
      } else if (type === "bad") {
        this.formData = {
          gender: "Female",
          ageGroup: "25-34",
          age: 28,
          creditScore: 540,
          income: 2500,
          loanAmount: 320000,
          propertyValue: 280000,
          ltv: 114,
          dti: 56,
          loanPurpose: "personal",
          creditType: "Subprime",
          loanType: "FHA",
          rateOfInterest: 7.5,
          term: 360,
        };
      } else {
        this.formData = {
          gender: "Male",
          ageGroup: "35-44",
          age: 38,
          creditScore: 680,
          income: 6500,
          loanAmount: 180000,
          propertyValue: 250000,
          ltv: 72,
          dti: 34,
          loanPurpose: "home",
          creditType: "Standard",
          loanType: "Conventional",
          rateOfInterest: 5.5,
          term: 360,
        };
      }
      this.result = null;
      this.error = null;
      this.updateDerived();
    },

    updateDerived() {
      this.formData.ltv = Number(this.calculatedLTV.toFixed(2));
      this.formData.dti = Number(this.calculatedDTI.toFixed(2));
    },

    async predict() {
      this.loading = true;
      this.error = null;
      this.result = null;
      this.updateDerived();

      try {
        if (!this.formData.gender || !this.formData.ageGroup) {
          throw new Error("Vui lòng chọn giới tính và nhóm tuổi.");
        }

        const payload = {
          Gender: this.formData.gender,
          AgeGroup: this.formData.ageGroup,
          Age: Number(this.formData.age) || null,
          CreditScore: Number(this.formData.creditScore),
          Income: Number(this.formData.income),
          LoanAmount: Number(this.formData.loanAmount),
          PropertyValue: Number(this.formData.propertyValue),
          LTV: Number(this.formData.ltv),
          DTI: Number(this.formData.dti),
          LoanPurpose: this.formData.loanPurpose,
          CreditType: this.formData.creditType || "Standard",
          LoanType: this.formData.loanType || "Conventional",
          RateOfInterest: Number(this.formData.rateOfInterest) || null,
          Term: Number(this.formData.term) || null,
        };

        const response = await fetch("/api/logistic-regression/predict", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });

        if (!response.ok) {
          const text = await response.text();
          throw new Error(text || "Không thể lấy kết quả từ server");
        }

        this.result = await response.json();
        this.renderChart();
      } catch (err) {
        this.error = err.message || "Đã có lỗi xảy ra";
      } finally {
        this.loading = false;
      }
    },

    getRiskColor(level) {
      if (!level) return "text-slate-500";
      if (level.includes("VERY HIGH") || level.includes("HIGH"))
        return "text-rose-600";
      if (level.includes("MEDIUM")) return "text-amber-600";
      return "text-emerald-600";
    },

    getRiskLevelVietnamese(level) {
      if (!level) return "N/A";
      const levelUpper = level.toUpperCase();
      if (levelUpper.includes("VERY HIGH")) return "RẤT CAO";
      if (levelUpper.includes("HIGH")) return "CAO";
      if (levelUpper.includes("MEDIUM")) return "TRUNG BÌNH";
      if (levelUpper.includes("LOW")) return "THẤP";
      if (levelUpper.includes("VERY LOW")) return "RẤT THẤP";
      return level;
    },

    getConfidenceLevelVietnamese(level) {
      if (!level) return "N/A";
      const levelUpper = level.toUpperCase();
      if (levelUpper.includes("HIGH")) return "Cao";
      if (levelUpper.includes("MEDIUM")) return "Trung bình";
      if (levelUpper.includes("LOW")) return "Thấp";
      return level;
    },

    getRiskBg(level) {
      if (!level) return "bg-slate-50";
      if (level.includes("VERY HIGH") || level.includes("HIGH"))
        return "bg-rose-50 border-rose-200";
      if (level.includes("MEDIUM")) return "bg-amber-50 border-amber-200";
      return "bg-emerald-50 border-emerald-200";
    },

    recommendationText() {
      return this.result?.Recommendation || "Chưa có khuyến nghị";
    },

    renderChart() {
      const dom = document.getElementById("riskChart");
      if (!dom || typeof echarts === "undefined" || !this.result) return;

      if (this.chartInstance) this.chartInstance.dispose();
      this.chartInstance = echarts.init(dom);

      const badProb = Math.max(
        0,
        Math.min(100, (this.result.BadDebtProbability || 0) * 100),
      );
      const goodProb = Math.max(
        0,
        Math.min(100, (this.result.GoodDebtProbability || 0) * 100),
      );

      this.chartInstance.setOption({
        tooltip: { trigger: "item" },
        legend: { bottom: 0, textStyle: { fontFamily: "Inter" } },
        series: [
          {
            type: "pie",
            radius: ["58%", "80%"],
            avoidLabelOverlap: false,
            label: { show: false },
            emphasis: {
              label: { show: true, fontSize: 16, fontWeight: "bold" },
            },
            data: [
              {
                value: badProb,
                name: "Nợ xấu",
                itemStyle: { color: "#ef4444" },
              },
              {
                value: goodProb,
                name: "An toàn",
                itemStyle: { color: "#10b981" },
              },
            ],
          },
        ],
      });

      window.addEventListener(
        "resize",
        () => this.chartInstance && this.chartInstance.resize(),
      );
    },
  };
}
