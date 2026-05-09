/**
 * Dashboard Application
 * Quản lý dashboard với charts và statistics
 */
function dashboardApp() {
    return {
        loading: true,
        error: null,
        data: null,
        ageChart: null,
        clusterChart: null,
        chartsRendered: false,

        async init() {
            await this.loadData();
        },

        cleanup() {
            if (this.ageChart) {
                this.ageChart.dispose();
                this.ageChart = null;
            }
            if (this.clusterChart) {
                this.clusterChart.dispose();
                this.clusterChart = null;
            }
            this.chartsRendered = false;
        },

        getLargestClusterName() {
            if (!this.data || !this.data.ClusterProfiles || this.data.ClusterProfiles.length === 0) return 'N/A';
            const largest = this.data.ClusterProfiles.reduce((prev, current) => 
                (prev.CustomerCount > current.CustomerCount) ? prev : current
            );
            return largest.ClusterDescription || ('Cluster ' + largest.ClusterID) || 'N/A';
        },

        fetchData() {
            this.loadData();
        },

        async loadData() {
            try {
                this.loading = true;
                this.error = null;

                const response = await fetch('/api/dashboard');
                if (!response.ok) throw new Error('Failed to load data');
                
                this.data = await response.json();
                
                // Check if data has error
                if (this.data && this.data.Error) {
                    throw new Error(this.data.Message || 'Unknown error');
                }
                
                console.log('Data loaded:', this.data);
                
                // Render charts after a short delay to ensure DOM is ready
                setTimeout(() => {
                    if (!this.chartsRendered) {
                        this.renderCharts();
                    }
                }, 300);
                
            } catch (err) {
                this.error = err.message;
                console.error('Error loading dashboard:', err);
            } finally {
                this.loading = false;
            }
        },

        renderCharts() {
            // Prevent multiple renders
            if (this.chartsRendered || !this.data) {
                console.log('Skipping chart render:', { chartsRendered: this.chartsRendered, hasData: !!this.data });
                return;
            }

            console.log('Rendering charts...');

            // Age Group Chart
            this.renderAgeGroupChart();

            // Cluster Chart
            this.renderClusterChart();

            // Mark charts as rendered
            this.chartsRendered = true;
            console.log('Charts rendered successfully');
        },

        renderAgeGroupChart() {
            const chartDom = document.getElementById('mainTrendChart');
            if (!chartDom || !this.data?.AgeGroupAnalysis || this.data.AgeGroupAnalysis.length === 0) return;

            if (this.ageChart) {
                this.ageChart.dispose();
            }

            this.ageChart = echarts.init(chartDom);
            
            // Generate some mock historical points based on AgeGroup to make a massive trend line
            const categories = this.data.AgeGroupAnalysis.map(a => a.Category);
            const approvalRates = this.data.AgeGroupAnalysis.map(a => a.ApprovalRate);
            
            // To make it look "hầm hố" (massive/impressive), let's create a smooth Area chart
            const option = {
                tooltip: {
                    trigger: 'axis',
                    axisPointer: { type: 'cross', label: { backgroundColor: '#6a7985' } },
                    backgroundColor: 'rgba(255, 255, 255, 0.95)',
                    borderColor: '#e2e8f0',
                    textStyle: { color: '#1e293b', fontFamily: 'Inter' },
                    extraCssText: 'box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1); border-radius: 8px;'
                },
                grid: {
                    left: '3%', right: '4%', bottom: '3%', top: '5%',
                    containLabel: true
                },
                xAxis: [
                    {
                        type: 'category',
                        boundaryGap: false,
                        data: categories,
                        axisLine: { lineStyle: { color: '#cbd5e1' } },
                        axisLabel: { color: '#64748b', fontFamily: 'Inter', fontWeight: 600 }
                    }
                ],
                yAxis: [
                    {
                        type: 'value',
                        max: 100,
                        axisLine: { show: false },
                        axisTick: { show: false },
                        splitLine: { lineStyle: { color: '#f1f5f9', type: 'dashed' } },
                        axisLabel: { color: '#64748b', fontFamily: 'Inter', formatter: '{value}%' }
                    }
                ],
                series: [
                    {
                        name: 'Tỷ lệ phê duyệt',
                        type: 'line',
                        smooth: 0.4,
                        symbol: 'circle',
                        symbolSize: 8,
                        showSymbol: false,
                        lineStyle: {
                            color: '#0ea5e9',
                            width: 4,
                            shadowColor: 'rgba(14, 165, 233, 0.5)',
                            shadowBlur: 10,
                            shadowOffsetY: 5
                        },
                        itemStyle: {
                            color: '#0ea5e9',
                            borderColor: '#fff',
                            borderWidth: 2
                        },
                        areaStyle: {
                            color: {
                                type: 'linear',
                                x: 0,
                                y: 0,
                                x2: 0,
                                y2: 1,
                                colorStops: [{
                                    offset: 0, color: 'rgba(14, 165, 233, 0.4)' // color at 0%
                                }, {
                                    offset: 1, color: 'rgba(14, 165, 233, 0.01)' // color at 100%
                                }]
                            }
                        },
                        data: approvalRates,
                        animationDuration: 2000,
                        animationEasing: 'cubicOut'
                    }
                ]
            };

            this.ageChart.setOption(option);
            
            // Responsive resize
            window.addEventListener('resize', () => {
                if (this.ageChart) this.ageChart.resize();
            });
        },

        renderClusterChart() {
            const chartDom = document.getElementById('clusterChart');
            if (!chartDom || !this.data?.ClusterProfiles || this.data.ClusterProfiles.length === 0) return;

            if (this.clusterChart) {
                this.clusterChart.dispose();
            }

            this.clusterChart = echarts.init(chartDom);

            const data = this.data.ClusterProfiles.map(c => ({
                value: c.CustomerCount,
                name: c.ClusterDescription || ('Cluster ' + c.ClusterID)
            }));

            const option = {
                tooltip: {
                    trigger: 'item',
                    backgroundColor: 'rgba(255, 255, 255, 0.95)',
                    borderColor: '#e2e8f0',
                    textStyle: { color: '#1e293b', fontFamily: 'Inter' },
                    extraCssText: 'box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1); border-radius: 8px;'
                },
                legend: {
                    bottom: '0%',
                    left: 'center',
                    icon: 'circle',
                    itemWidth: 10,
                    textStyle: { fontFamily: 'Inter', color: '#64748b', fontSize: 12 }
                },
                color: ['#0ea5e9', '#8b5cf6', '#f59e0b', '#10b981', '#f43f5e'],
                series: [
                    {
                        name: 'Phân Cụm',
                        type: 'pie',
                        radius: ['55%', '80%'],
                        center: ['50%', '45%'],
                        avoidLabelOverlap: false,
                        itemStyle: {
                            borderRadius: 6,
                            borderColor: '#fff',
                            borderWidth: 2
                        },
                        label: {
                            show: false,
                            position: 'center'
                        },
                        emphasis: {
                            label: {
                                show: true,
                                fontSize: 20,
                                fontWeight: 'bold',
                                fontFamily: 'Inter',
                                formatter: '{c}\nKH'
                            },
                            itemStyle: {
                                shadowBlur: 10,
                                shadowOffsetX: 0,
                                shadowColor: 'rgba(0, 0, 0, 0.1)'
                            }
                        },
                        labelLine: { show: false },
                        data: data,
                        animationType: 'scale',
                        animationEasing: 'elasticOut',
                        animationDelay: function (idx) {
                            return Math.random() * 200;
                        }
                    }
                ]
            };

            this.clusterChart.setOption(option);
            
            // Responsive resize
            window.addEventListener('resize', () => {
                if (this.clusterChart) this.clusterChart.resize();
            });
        }
    }
}
