const COLOR_DARK = '#757d85'
const COLOR_ELIASDH = '#4f94f0'
const COLOR_BLURPLE = '#526DD1'
const COLOR_YELLOW = '#ffe5a0'
const COLOR_RED = '#ffcfc9'

const swapTitle = function() {
	const titleElements = document.getElementsByTagName('title');
	titleElements[0].innerText = 'EliasDH - Cluster';
};

const swapIcon = function() {
	const linkElements = document.getElementsByTagName('link');
	for (var i = 0; i < linkElements.length; i++) {
		var node = linkElements[i];
		if (node.rel === 'apple-touch-icon') {
			node.href = '/pve2/images/dh_logo-eliasdh.png';
			break;
		}
	}
};

const swapLogo = async function() {
	const imgElements = document.getElementsByTagName('img');
	var found = false;
	for (var i = 0; i< imgElements.length; i++) {
		var node = imgElements[i]
		if (node.src.includes('proxmox_logo.png')) {
			found = true;
			var width = (node.parentElement.clientWidth == undefined || node.parentElement.clientWidth == 0) ? 172 : node.parentElement.clientWidth;
			var height = (node.parentElement.clientHeight == undefined || node.parentElement.clientHeight == 0) ? 30 : node.parentElement.clientHeight;
			node.setAttribute('height', `${height}px`);
			node.setAttribute('width', `${width}px`);
			node.setAttribute('src', '/pve2/images/dh_logo.png');
			node.setAttribute('style', 'color: white');
		}
	}
	if (!found) {
		await new Promise(resolve => setTimeout(resolve, 60));
		await swapLogo();
	};
};

const patchCharts = function() {
	Ext.chart.theme.Base.prototype.config.chart.defaults.background = COLOR_ELIASDH;
	Ext.chart.theme.Base.prototype.config.axis.defaults.label.color = 'black';
	Ext.chart.theme.Base.prototype.config.axis.defaults.title.color = 'black';
	Ext.chart.theme.Base.prototype.config.axis.defaults.style.strokeStyle = COLOR_BLURPLE;
	Ext.chart.theme.Base.prototype.config.axis.defaults.grid.strokeStyle = 'rgba(44, 47, 51, 1)'; // COLOR_DARK
	Ext.chart.theme.Base.prototype.config.sprites.text.color = 'black';
};

function patchGaugeWidget() {
	Proxmox.panel.GaugeWidget.prototype.backgroundColor = COLOR_DARK;
	Proxmox.panel.GaugeWidget.prototype.criticalColor = COLOR_RED;
	Proxmox.panel.GaugeWidget.prototype.warningColor = COLOR_YELLOW;
	Proxmox.panel.GaugeWidget.prototype.defaultColor = COLOR_BLURPLE;
	Proxmox.panel.GaugeWidget.prototype.items[1].series[0].colors[0] = COLOR_DARK;
};

function patchBackupConfig() {
	PVE.window.BackupConfig.prototype.items.style['background-color'] = COLOR_ELIASDH;
};

function patchDiskSmartWindow() {
	const target = PVE.DiskSmartWindow || Proxmox.window.DiskSmart;
	target.prototype.items[1].style['background-color'] = COLOR_ELIASDH;
}

function patchTFAEdit() {
	if (PVE.window.TFAEdit) PVE.window.TFAEdit.prototype.items[0].items[0].items[1].style["background-color"] = 'transparent';
}

function patchCreateWidget() {
	_createWidget = Ext.createWidget
	Ext.createWidget = function(c, p) {
		if (typeof p === 'object' && typeof p.style === 'object') {
			if (c === 'component' && typeof p.style['background-color'] === 'string' && p.style['background-color'] === 'white') p.style['background-color'] = COLOR_DARK
		}
		return _createWidget(c, p)
	}
}

swapTitle();
swapIcon();
swapLogo();
patchCharts();
patchGaugeWidget();
patchBackupConfig();
patchDiskSmartWindow();
patchTFAEdit();
patchCreateWidget();
console.log('PVECustomTheme :: Patched');
