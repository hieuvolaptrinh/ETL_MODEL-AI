class AppHeader extends HTMLElement {
    constructor() {
        super();
    }

    connectedCallback() {
        const currentPage = this.getAttribute('current-page') || '';
        
        // Define navigation items
        const navItems = [
            { id: 'dashboard', name: 'Dashboard', href: '/index.html', icon: 'fa-chart-line' },
            { id: 'prediction', name: 'Decision Tree', href: '/Pages/prediction.html', icon: 'fa-code-branch' },
            { id: 'logistic', name: 'Logistic Regression', href: '/Pages/logistic.html', icon: 'fa-chart-pie' },
            { id: 'clustering', name: 'Clustering', href: '/Pages/clustering.html', icon: 'fa-layer-group' }
        ];

        // Generate nav links
        const navHtml = navItems.map(item => {
            const isActive = item.id === currentPage;
            const baseClasses = "px-4 py-2 text-sm font-semibold rounded-lg transition-colors flex items-center gap-2";
            const activeClasses = "text-primary bg-primary/10";
            const inactiveClasses = "text-slate-500 hover:text-slate-800 hover:bg-slate-100";
            
            return `<a href="${item.href}" class="${baseClasses} ${isActive ? activeClasses : inactiveClasses}">
                        <i class="fa-solid ${item.icon} ${isActive ? '' : 'opacity-70'}"></i> <span class="hidden md:inline">${item.name}</span>
                    </a>`;
        }).join('');

        this.innerHTML = `
            <header class="bg-white border-b border-slate-200 sticky top-0 z-50 shadow-sm">
                <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div class="flex justify-between items-center h-16">
                        <!-- Logo -->
                        <div class="flex items-center space-x-6">
                            <a href="/index.html" class="flex items-center space-x-3">
                                <div class="w-10 h-10 bg-slate-900 rounded-xl flex items-center justify-center text-white shadow-md">
                                    <i class="fa-solid fa-cube text-xl"></i>
                                </div>
                                <div class="hidden sm:block">
                                    <h1 class="text-xl font-bold text-slate-900 tracking-tight">CIC Analytics</h1>
                                    <p class="text-[10px] uppercase tracking-wider text-slate-500 font-bold leading-none">Hệ thống AI rủi ro</p>
                                </div>
                            </a>
                            
                            <!-- Desktop Nav -->
                            <nav class="flex space-x-1 sm:border-l sm:border-slate-200 sm:pl-6">
                                ${navHtml}
                            </nav>
                        </div>
                    </div>
                </div>
            </header>
        `;
    }
}

customElements.define('app-header', AppHeader);
