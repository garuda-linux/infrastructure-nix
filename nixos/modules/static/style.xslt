<?xml version="1.0"?>
<!--
dirlist.xslt - transform nginx's into lighttpd look-alike dirlistings

I'm currently switching over completely from lighttpd to nginx. If you come
up with a prettier stylesheet or other improvements, please tell me :)

-->
<!--
Copyright (c) 2016 by Moritz Wilhelmy <mw@barfooze.de>
	All rights reserved

	Redistribution and use in source and binary forms, with or without
	modification, are permitted providing that the following conditions
	are met:
	1. Redistributions of source code must retain the above copyright
	notice, this list of conditions and the following disclaimer.
	2. Redistributions in binary form must reproduce the above copyright
	notice, this list of conditions and the following disclaimer in the
	documentation and/or other materials provided with the distribution.

	THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
	IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
	DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
	DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
	OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
	HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
	STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
	IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
	POSSIBILITY OF SUCH DAMAGE.
-->
<!DOCTYPE fnord [
  <!ENTITY nbsp "&#160;">
]>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:func="http://exslt.org/functions"
  xmlns:str="http://exslt.org/strings"
  version="1.0"
  exclude-result-prefixes="xhtml"
  extension-element-prefixes="func str">
  <xsl:output method="xml" version="1.0" encoding="UTF-8" doctype-public="-//W3C//DTD XHTML 1.1//EN"
    doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" indent="no"
    media-type="application/xhtml+xml" />
  <xsl:strip-space elements="*" />
  <xsl:template name="size">
    <xsl:param name="bytes" />
				<xsl:choose>
      <xsl:when test="string(number($bytes)) = 'NaN'"> - </xsl:when>
      <xsl:when test="$bytes &lt; 1000">
        <xsl:value-of select="$bytes" />B </xsl:when>
      <xsl:when test="$bytes &lt; 1048576">
        <xsl:value-of select="format-number($bytes div 1024, '0.0')" />K </xsl:when>
      <xsl:when test="$bytes &lt; 1073741824">
        <xsl:value-of select="format-number($bytes div 1048576, '0.0')" />M </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="format-number(($bytes div 1073741824), '0.00')" />G </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="timestamp">
    <xsl:param name="iso-timestamp" />
				<xsl:value-of
      select="concat(substring($iso-timestamp, 0, 11), ' ', substring($iso-timestamp, 12, 5))" />
  </xsl:template>
  <xsl:template match="directory">
    <tr class="entry-row">
      <td class="icon-col icon">
        <svg xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false"
          data-prefix="far" data-icon="folder" class="svg-inline--fa fa-folder fa-w-16" role="img"
          viewBox="0 0 512 512">
          <path fill="currentColor"
            d="M464 128H272l-54.63-54.63c-6-6-14.14-9.37-22.63-9.37H48C21.49 64 0 85.49 0 112v288c0 26.51 21.49 48 48 48h416c26.51 0 48-21.49 48-48V176c0-26.51-21.49-48-48-48zm0 272H48V112h140.12l54.63 54.63c6 6 14.14 9.37 22.63 9.37H464v224z" />
        </svg>
      </td>
      <td class="name-col">
        <a href="{str:encode-uri(current(),true())}/">
          <xsl:value-of select="." />
        </a>
      </td>
      <td class="date-col">
        <xsl:call-template name="timestamp">
          <xsl:with-param name="iso-timestamp" select="@mtime" />
        </xsl:call-template>
      </td>
      <td class="size-col text-right">-</td>
      <td class="type-col text-right">Directory</td>
    </tr>
  </xsl:template>
  <xsl:template match="file|other">
    <tr class="entry-row">
      <td class="icon-col icon file-icon"></td>
      <td class="name-col">
        <a href="{str:encode-uri(current(),true())}">
          <xsl:value-of select="." />
        </a>
      </td>
      <td class="date-col">
        <xsl:call-template name="timestamp">
          <xsl:with-param name="iso-timestamp" select="@mtime" />
        </xsl:call-template>
      </td>
      <td class="size-col text-right">
        <xsl:call-template name="size">
          <xsl:with-param name="bytes" select="@size" />
        </xsl:call-template>
      </td>
      <td class="type-col text-right">File</td>
    </tr>
  </xsl:template>
  <xsl:template match="/">
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <meta charset="UTF-8" />

        <title> Index of <xsl:value-of select="$path" />
        </title>
        <style type="text/css">
          :root{
          --bg:#11111b;
          --surface:#1e1e2e;
          --surface-2:#181825;
          --border:#313244;
          --text:#cdd6f4;
          --muted:#a6adc8;
          --mauve:#cba6f7;
          --blue:#89b4fa;
          --teal:#94e2d5;
          --pink:#f5c2e7;
          }
          *{box-sizing:border-box;}
          html,body{margin:0;padding:0;}
          body {
          font-family: Inter, ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto,
          Helvetica, Arial, sans-serif;
          background: radial-gradient(circle at top right, #1e1e2e 0%, #11111b 55%);
          color: var(--text);
          min-height: 100vh;
          }
          a{
          color:var(--blue);
          text-decoration:none;
          transition:color .15s ease;
          }
          a:hover{color:var(--mauve);}
          .container{
          max-width:1100px;
          margin:0 auto;
          padding:2rem 1rem 1.25rem;
          }
          .topbar{
          display:flex;
          align-items:center;
          justify-content:space-between;
          gap:1rem;
          flex-wrap:wrap;
          margin-bottom:1rem;
          }
          .brand{
          font-size:2rem;
          font-weight:800;
          letter-spacing:-0.03em;
          color:var(--text);
          }
          .path{
          color:var(--muted);
          font-size:.95rem;
          }
          .search-box{
          appearance:none;
          border:1px solid var(--border);
          background:var(--surface-2);
          color:var(--text);
          border-radius:10px;
          padding:.58rem .78rem;
          min-width:260px;
          outline:none;
          transition:border-color .15s ease, box-shadow .15s ease;
          }
          .search-box::placeholder{color:var(--muted);}
          .search-box:focus{
          border-color:var(--mauve);
          box-shadow:0 0 0 3px rgba(203,166,247,.2);
          }
          .panel{
          background:linear-gradient(180deg,rgba(30,30,46,.9) 0%,rgba(24,24,37,.94) 100%);
          border:1px solid var(--border);
          border-radius:14px;
          overflow:hidden;
          box-shadow:0 10px 26px rgba(0,0,0,.28);
          }
          table{width:100%;border-collapse:collapse;}
          thead tr{
          background:rgba(203,166,247,.08);
          border-bottom:1px solid var(--border);
          }
          thead td{
          padding:.72rem .55rem;
          font-size:.82rem;
          font-weight:700;
          letter-spacing:.02em;
          color:var(--pink);
          text-transform:uppercase;
          }
          .entry-row{border-bottom:1px solid rgba(49,50,68,.7);}
    .entry-row:hover{background:rgba(137,180,250,.08);}
    .icon-col,.name-col,.date-col,.size-col,.type-col{padding:.66rem .55rem;}
    .icon-col{width:36px;color:var(--teal);}
          .name-col{width:48%;}
          .date-col{color:var(--muted);}
          .size-col,.type-col{color:var(--muted);}
          .text-right{text-align:right;}
          .file-icon{
          content:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg'
    aria-hidden='true' focusable='false' data-prefix='fas' data-icon='file' class='svg-inline--fa
    fa-file fa-w-12' role='img' viewBox='0 0 384 512'%3E%3Cpath fill='currentColor' d='M224
    136V0H24C10.7 0 0 10.7 0 24v464c0 13.3 10.7 24 24 24h336c13.3 0 24-10.7 24-24V160H248c-13.2
    0-24-10.8-24-24zm160-14.1v6.1H256V0h6.1c6.4 0 12.5 2.5 17 7l97.9 98c4.5 4.5 7 10.6 7
    16.9z'/%3E%3C/svg%3E");
          }
          .footer{
          display:flex;
          justify-content:space-between;
          gap:1rem;
          flex-wrap:wrap;
          padding:.95rem .2rem 0;
          font-size:.86rem;
          color:var(--muted);
          }
          @media (max-width:820px){
          .type-col,thead td:nth-child(5){display:none;}
          .name-col{width:auto;}
          }
          @media (max-width:620px){
          .date-col,thead td:nth-child(3){display:none;}
          .search-box{width:100%;min-width:0;}
          .topbar{align-items:stretch;}
          .brand{font-size:1.6rem;}
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="topbar">
            <div>
              <div class="brand">
                <xsl:value-of select="$hostname" />
              </div>
              <div class="path">Index of <xsl:value-of select="$path" /></div>
            </div>
            <input
              type="search"
              id="search-box"
              oninput="handleSearch()"
              placeholder="Filter files and directories"
              class="search-box"
            />
          </div>
          <div class="panel">
            <table summary="Directory Listing">
              <thead>
                <tr>
                  <td></td>
                  <td>Name</td>
                  <td>Last Modified</td>
                  <td class="text-right">Size</td>
                  <td class="text-right">Type</td>
                </tr>
              </thead>
              <tbody>
                <tr class="entry-row">
                  <td class="icon-col icon"></td>
                  <td class="name-col">
                    <a href="../">
                      <svg xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false"
                        data-prefix="fas" data-icon="level-up-alt" style="height: 16px"
                        class="svg-inline--fa fa-level-up-alt fa-w-10" role="img"
                        viewBox="0 0 320 512">
                        <path fill="currentColor"
                          d="M313.553 119.669L209.587 7.666c-9.485-10.214-25.676-10.229-35.174 0L70.438 119.669C56.232 134.969 67.062 160 88.025 160H152v272H68.024a11.996 11.996 0 0 0-8.485 3.515l-56 56C-4.021 499.074 1.333 512 12.024 512H208c13.255 0 24-10.745 24-24V160h63.966c20.878 0 31.851-24.969 17.587-40.331z" />
                      </svg>
                    </a>
                  </td>
                  <td class="date-col"></td>
                  <td class="size-col text-right"></td>
                  <td class="type-col text-right"></td>
                </tr>
                <xsl:apply-templates />
              </tbody>
            </table>
          </div>
          <div class="footer">
            <div>
              <xsl:value-of select="count(//directory)" /> Directories, <xsl:value-of
                select="count(//file)" /> Files, <xsl:call-template name="size">
                <xsl:with-param name="bytes" select="sum(//file/@size)" />
              </xsl:call-template>
    Total </div>
            <div class="foot">powered by Nginx</div>
          </div>
          <script>
            const searchBox = document.querySelector("#search-box");
            searchBox.style.display = "";

            if (window.location.hash) {
            searchBox.value = window.location.hash.split("#")[1];
            handleSearch();
            }

            function handleSearch() {
            const filter = searchBox.value.toUpperCase();
            window.location.hash = searchBox.value;
            const table = document.querySelector("table");
            const rows = [...table.querySelectorAll("tr")].splice(2);

            rows.forEach((tr) => {
            const td = tr.querySelector("td:nth-child(2)");

            if (!td) {
            return;
            }

            const tdContent = td.textContent || td.innerText;
            tr.style.display = tdContent.toUpperCase().includes(filter) ? "" : "none";
            });
            }
          </script>
        </div>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>