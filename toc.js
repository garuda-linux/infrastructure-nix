// Populate the sidebar
//
// This is a script, and not included directly in the page, to control the total size of the book.
// The TOC contains an entry for each page, so if each page includes a copy of the TOC,
// the total size of the page becomes O(n**2).
class MDBookSidebarScrollbox extends HTMLElement {
    constructor() {
        super();
    }
    connectedCallback() {
        this.innerHTML = '<ol class="chapter"><li class="chapter-item expanded affix "><li class="part-title">Welcome</li><li class="chapter-item expanded "><a href="intro.html"><strong aria-hidden="true">1.</strong> Introduction</a></li><li class="chapter-item expanded "><a href="general.html"><strong aria-hidden="true">2.</strong> General information</a></li><li class="chapter-item expanded "><a href="common.html"><strong aria-hidden="true">3.</strong> Common tasks</a></li><li class="chapter-item expanded "><a href="important-links.html"><strong aria-hidden="true">4.</strong> Important links</a></li><li class="chapter-item expanded affix "><li class="part-title">Users</li><li class="chapter-item expanded "><a href="users.html"><strong aria-hidden="true">5.</strong> Users</a></li><li><ol class="section"><li class="chapter-item expanded "><a href="users/current_users.html"><strong aria-hidden="true">5.1.</strong> Current users</a></li></ol></li><li class="chapter-item expanded "><li class="part-title">Hosts</li><li class="chapter-item expanded "><a href="hosts/immortalis.html"><strong aria-hidden="true">6.</strong> immortalis</a></li><li><ol class="section"><li class="chapter-item expanded "><a href="nixos-containers/docker.html"><strong aria-hidden="true">6.1.</strong> docker</a></li><li class="chapter-item expanded "><a href="nixos-containers/docker-proxied.html"><strong aria-hidden="true">6.2.</strong> docker-proxied</a></li><li class="chapter-item expanded "><a href="nixos-containers/forum.html"><strong aria-hidden="true">6.3.</strong> forum</a></li><li class="chapter-item expanded "><a href="nixos-containers/github-runner.html"><strong aria-hidden="true">6.4.</strong> github-runner</a></li><li class="chapter-item expanded "><a href="nixos-containers/lemmy.html"><strong aria-hidden="true">6.5.</strong> lemmy</a></li><li class="chapter-item expanded "><a href="nixos-containers/mastodon.html"><strong aria-hidden="true">6.6.</strong> mastodon</a></li><li class="chapter-item expanded "><a href="nixos-containers/mongodb.html"><strong aria-hidden="true">6.7.</strong> mongodb</a></li><li class="chapter-item expanded "><a href="nixos-containers/postgres.html"><strong aria-hidden="true">6.8.</strong> postgres</a></li><li class="chapter-item expanded "><a href="nixos-containers/web-front.html"><strong aria-hidden="true">6.9.</strong> web-front</a></li></ol></li><li class="chapter-item expanded "><a href="hosts/garuda-mail.html"><strong aria-hidden="true">7.</strong> garuda-mail</a></li><li class="chapter-item expanded affix "><li class="part-title">Repository infrastructure</li><li class="chapter-item expanded "><a href="repositories/general.html"><strong aria-hidden="true">8.</strong> General information</a></li><li class="chapter-item expanded "><a href="repositories/pkgbuilds.html"><strong aria-hidden="true">9.</strong> PKGBUILDs</a></li><li class="chapter-item expanded affix "><li class="part-title">Services</li><li class="chapter-item expanded "><a href="services/chaotic-4.0.html"><strong aria-hidden="true">10.</strong> Chaotic 4.0</a></li><li class="chapter-item expanded "><a href="services/discourse.html"><strong aria-hidden="true">11.</strong> Discourse</a></li><li class="chapter-item expanded "><a href="websites/documentation.html"><strong aria-hidden="true">12.</strong> Documentation</a></li><li class="chapter-item expanded "><a href="services/tailscale.html"><strong aria-hidden="true">13.</strong> Tailscale</a></li><li class="chapter-item expanded affix "><li class="part-title">Misc</li><li class="chapter-item expanded "><a href="code-of-conduct.html"><strong aria-hidden="true">14.</strong> Code of Conduct</a></li><li class="chapter-item expanded "><a href="privacy-policy.html"><strong aria-hidden="true">15.</strong> Privacy policy</a></li><li class="chapter-item expanded "><a href="security.html"><strong aria-hidden="true">16.</strong> Security</a></li><li class="chapter-item expanded "><a href="credits.html"><strong aria-hidden="true">17.</strong> Credits</a></li></ol>';
        // Set the current, active page, and reveal it if it's hidden
        let current_page = document.location.href.toString();
        if (current_page.endsWith("/")) {
            current_page += "index.html";
        }
        var links = Array.prototype.slice.call(this.querySelectorAll("a"));
        var l = links.length;
        for (var i = 0; i < l; ++i) {
            var link = links[i];
            var href = link.getAttribute("href");
            if (href && !href.startsWith("#") && !/^(?:[a-z+]+:)?\/\//.test(href)) {
                link.href = path_to_root + href;
            }
            // The "index" page is supposed to alias the first chapter in the book.
            if (link.href === current_page || (i === 0 && path_to_root === "" && current_page.endsWith("/index.html"))) {
                link.classList.add("active");
                var parent = link.parentElement;
                if (parent && parent.classList.contains("chapter-item")) {
                    parent.classList.add("expanded");
                }
                while (parent) {
                    if (parent.tagName === "LI" && parent.previousElementSibling) {
                        if (parent.previousElementSibling.classList.contains("chapter-item")) {
                            parent.previousElementSibling.classList.add("expanded");
                        }
                    }
                    parent = parent.parentElement;
                }
            }
        }
        // Track and set sidebar scroll position
        this.addEventListener('click', function(e) {
            if (e.target.tagName === 'A') {
                sessionStorage.setItem('sidebar-scroll', this.scrollTop);
            }
        }, { passive: true });
        var sidebarScrollTop = sessionStorage.getItem('sidebar-scroll');
        sessionStorage.removeItem('sidebar-scroll');
        if (sidebarScrollTop) {
            // preserve sidebar scroll position when navigating via links within sidebar
            this.scrollTop = sidebarScrollTop;
        } else {
            // scroll sidebar to current active section when navigating via "next/previous chapter" buttons
            var activeSection = document.querySelector('#sidebar .active');
            if (activeSection) {
                activeSection.scrollIntoView({ block: 'center' });
            }
        }
        // Toggle buttons
        var sidebarAnchorToggles = document.querySelectorAll('#sidebar a.toggle');
        function toggleSection(ev) {
            ev.currentTarget.parentElement.classList.toggle('expanded');
        }
        Array.from(sidebarAnchorToggles).forEach(function (el) {
            el.addEventListener('click', toggleSection);
        });
    }
}
window.customElements.define("mdbook-sidebar-scrollbox", MDBookSidebarScrollbox);
