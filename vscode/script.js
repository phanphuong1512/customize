/* =============================================================================
   VS Code Custom Script - Command Palette Blur Effect
   =============================================================================
   Description: Adds backdrop blur effect when command palette is open
   ============================================================================= */

class VSCodeCustomizer {
    constructor() {
        this.BLUR_ELEMENT_ID = 'command-blur';
        this.COMMAND_DIALOG_SELECTOR = '.quick-input-widget';
        this.WORKBENCH_SELECTOR = '.monaco-workbench';
        this.STICKY_WIDGET_SELECTOR = '.sticky-widget';
        this.TREE_WIDGET_SELECTOR = '.monaco-tree-sticky-container';
        this.CHECK_INTERVAL = 500;

        this.init();
    }

    init() {
        document.addEventListener('DOMContentLoaded', () => {
            this.setupCommandDialogObserver();
            this.setupKeyboardListeners();
        });
    }

    setupCommandDialogObserver() {
        const checkElement = setInterval(() => {
            const commandDialog = document.querySelector(this.COMMAND_DIALOG_SELECTOR);

            if (commandDialog) {
                // Apply blur effect if command dialog is visible
                if (commandDialog.style.display !== 'none') {
                    this.showBlurEffect();
                }

                // Observe style changes
                const observer = new MutationObserver((mutations) => {
                    mutations.forEach((mutation) => {
                        if (mutation.type === 'attributes' && mutation.attributeName === 'style') {
                            if (commandDialog.style.display === 'none') {
                                this.hideBlurEffect();
                            } else {
                                this.showBlurEffect();
                            }
                        }
                    });
                });

                observer.observe(commandDialog, { attributes: true });
                clearInterval(checkElement);
            }
        }, this.CHECK_INTERVAL);
    }

    setupKeyboardListeners() {
        // Command palette shortcut (Cmd/Ctrl + P)
        document.addEventListener('keydown', (event) => {
            if ((event.metaKey || event.ctrlKey) && event.key === 'p') {
                event.preventDefault();
                this.showBlurEffect();
            } else if (this.isEscapeKey(event)) {
                event.preventDefault();
                this.hideBlurEffect();
            }
        });

        // Global escape key listener
        document.addEventListener('keydown', (event) => {
            if (this.isEscapeKey(event)) {
                this.hideBlurEffect();
            }
        }, true);
    }

    isEscapeKey(event) {
        return event.key === 'Escape' || event.key === 'Esc';
    }

    showBlurEffect() {
        const targetDiv = document.querySelector(this.WORKBENCH_SELECTOR);
        if (!targetDiv) return;

        // Remove existing blur element
        this.removeBlurElement();

        // Create new blur element
        const blurElement = document.createElement('div');
        blurElement.id = this.BLUR_ELEMENT_ID;
        blurElement.addEventListener('click', () => this.hideBlurEffect());

        targetDiv.appendChild(blurElement);

        // Hide sticky widgets
        this.toggleStickyWidgets(false);
    }

    hideBlurEffect() {
        this.removeBlurElement();
        this.toggleStickyWidgets(true);
    }

    removeBlurElement() {
        const existingElement = document.getElementById(this.BLUR_ELEMENT_ID);
        if (existingElement) {
            existingElement.remove();
        }
    }

    toggleStickyWidgets(show) {
        const opacity = show ? 1 : 0;

        // Toggle regular sticky widgets
        const stickyWidgets = document.querySelectorAll(this.STICKY_WIDGET_SELECTOR);
        stickyWidgets.forEach(widget => {
            widget.style.opacity = opacity;
        });

        // Toggle tree sticky widget
        const treeWidget = document.querySelector(this.TREE_WIDGET_SELECTOR);
        if (treeWidget) {
            treeWidget.style.opacity = opacity;
        }
    }
}

// Initialize the customizer
new VSCodeCustomizer();
