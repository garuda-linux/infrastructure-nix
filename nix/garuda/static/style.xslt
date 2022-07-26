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
	<!--
		Copyright (c) 2021 by Abdus S. Azad <abdus@abdus.net>
		All rights reserved

		CHANGELOG:
		1. Add CSS for page beautification
		2. Make page Responsive
		3. Add Search Box
		4. Add File-type Icon
	-->
			<!DOCTYPE fnord [


			<!ENTITY nbsp "&#160;">]>
			<xsl:stylesheet
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:xhtml="http://www.w3.org/1999/xhtml"
				xmlns="http://www.w3.org/1999/xhtml"
				xmlns:func="http://exslt.org/functions"
				xmlns:str="http://exslt.org/strings" version="1.0" exclude-result-prefixes="xhtml" extension-element-prefixes="func str">
			<xsl:output method="xml" version="1.0" encoding="UTF-8" doctype-public="-//W3C//DTD XHTML 1.1//EN" doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" indent="no" media-type="application/xhtml+xml"/>
			<xsl:strip-space elements="*" />
			<xsl:template name="size">
				<!-- transform a size in bytes into a human readable representation -->
				<xsl:param name="bytes"/>
				<xsl:choose>
					<xsl:when test="string(number($bytes)) = 'NaN'">
						-
					</xsl:when>
					<xsl:when test="$bytes &lt; 1000">
						<xsl:value-of select="$bytes" />B
					</xsl:when>
					<xsl:when test="$bytes &lt; 1048576">
						<xsl:value-of select="format-number($bytes div 1024, '0.0')" />K
					</xsl:when>
					<xsl:when test="$bytes &lt; 1073741824">
						<xsl:value-of select="format-number($bytes div 1048576, '0.0')" />M
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="format-number(($bytes div 1073741824), '0.00')" />G
					</xsl:otherwise>
				</xsl:choose>
			</xsl:template>
			<xsl:template name="timestamp">
				<!-- transform an ISO 8601 timestamp into a human readable representation -->
				<xsl:param name="iso-timestamp" />
				<xsl:value-of select="concat(substring($iso-timestamp, 0, 11), ' ', substring($iso-timestamp, 12, 5))" />
			</xsl:template>
			<xsl:template match="directory">
				<tr class="hover:bg-gray-300 transition-colors ease-in-out border-b">
					<td class="icon px-1 py-2 w-8">
						<svg xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false" data-prefix="far" data-icon="folder" class="svg-inline--fa fa-folder fa-w-16" role="img" viewBox="0 0 512 512"><path fill="currentColor" d="M464 128H272l-54.63-54.63c-6-6-14.14-9.37-22.63-9.37H48C21.49 64 0 85.49 0 112v288c0 26.51 21.49 48 48 48h416c26.51 0 48-21.49 48-48V176c0-26.51-21.49-48-48-48zm0 272H48V112h140.12l54.63 54.63c6 6 14.14 9.37 22.63 9.37H464v224z"/></svg>
					</td>
					<td class="px-1 py-2">
						<a href="{str:encode-uri(current(),true())}/">
							<xsl:value-of select="."/>
						</a>
					</td>
					<td class="px-1 py-2">
						<xsl:call-template name="timestamp">
							<xsl:with-param name="iso-timestamp" select="@mtime" />
						</xsl:call-template>
					</td>
					<td class="px-1 py-2 text-right"> - </td>
					<td class="px-1 py-2 text-right">Directory</td>
				</tr>
			</xsl:template>
			<xsl:template match="file|other">
				<tr class="hover:bg-gray-300 transition-colors ease-in-out border-b">
					<td class="icon px-1 py-2 w-6 file-icon"></td>
					<td class="px-1 py-2">
						<a href="{str:encode-uri(current(),true())}">
							<xsl:value-of select="." />
						</a>
					</td>
					<td class="px-1 py-2">
						<xsl:call-template name="timestamp">
							<xsl:with-param name="iso-timestamp" select="@mtime" />
						</xsl:call-template>
					</td>
					<td class="px-1 py-2 text-right">
						<xsl:call-template name="size">
							<xsl:with-param name="bytes" select="@size" />
						</xsl:call-template>
					</td>
					<td class="px-1 py-2 text-right">File</td>
				</tr>
			</xsl:template>
			<xsl:template match="/">
				<html>
					<head>
						<style type="text/css"></style>
						<meta name="viewport" content="width=device-width, initial-scale=1.0" />
						<meta charset="UTF-8" />

						<title>
								Index of

							<xsl:value-of select="$path"/>
						</title>
						<style type="text/css">
								/*! CSS Used from: https://unpkg.com/tailwindcss@%5E2/dist/tailwind.min.css */
								*,::after,::before{box-sizing:border-box;}
								::-moz-focus-inner{border-style:none;padding:0;}
								:-moz-focusring{outline:1px dotted ButtonText;}
								*,::after,::before{box-sizing:border-box;border-width:0;border-style:solid;border-color:currentColor;}
								*,::after,::before{--tw-border-opacity:1;border-color:rgba(229,231,235,var(--tw-border-opacity));}
								*,::after,::before{--tw-shadow:0 0 #0000;}
								*,::after,::before{--tw-ring-inset:var(--tw-empty, );--tw-ring-offset-width:0px;--tw-ring-offset-color:#fff;--tw-ring-color:rgba(59, 130, 246, 0.5);--tw-ring-offset-shadow:0 0 #0000;--tw-ring-shadow:0 0 #0000;}
								/*! CSS Used from: Embedded */
								*,::after,::before{box-sizing:border-box;}
								*,::after,::before{box-sizing:border-box;border-width:0;border-style:solid;border-color:currentColor;}
								*,::after,::before{--tw-border-opacity:1;border-color:rgba(229,231,235,var(--tw-border-opacity));}
								/*! CSS Used from: https://unpkg.com/tailwindcss@%5E2/dist/tailwind.min.css */
								*,::after,::before{box-sizing:border-box;}
								body{margin:0;}
								body{font-family:system-ui,-apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif,'Apple Color Emoji','Segoe UI Emoji';}
								table{text-indent:0;border-color:inherit;}
								input{font-family:inherit;font-size:100%;line-height:1.15;margin:0;}
								::-moz-focus-inner{border-style:none;padding:0;}
								:-moz-focusring{outline:1px dotted ButtonText;}
								[type=search]{-webkit-appearance:textfield;outline-offset:-2px;}
								*,::after,::before{box-sizing:border-box;border-width:0;border-style:solid;border-color:currentColor;}
								input::placeholder{opacity:1;color:#9ca3af;}
								table{border-collapse:collapse;}
								a{color:inherit;text-decoration:inherit;}
								input{padding:0;line-height:inherit;color:inherit;}
								svg{display:block;vertical-align:middle;}
								*,::after,::before{--tw-border-opacity:1;border-color:rgba(229,231,235,var(--tw-border-opacity));}
								.container{width:100%;}
								@media (min-width:640px){
								.container{max-width:640px;}
								}
								@media (min-width:768px){
								.container{max-width:768px;}
								}
								@media (min-width:1024px){
								.container{max-width:1024px;}
								}
								@media (min-width:1280px){
								.container{max-width:1280px;}
								}
								@media (min-width:1536px){
								.container{max-width:1536px;}
								}
								.sticky{position:sticky;}
								.z-20{z-index:20;}
								.mx-auto{margin-left:auto;margin-right:auto;}
								.flex{display:flex;}
								.w-6{width:1.5rem;}
								.w-8{width:2rem;}
								.w-full{width:100%;}
								.table-auto{table-layout:auto;}
								.border-collapse{border-collapse:collapse;}
								.justify-between{justify-content:space-between;}
								.border{border-width:1px;}
								.border-b{border-bottom-width:1px;}
								.border-gray-300{--tw-border-opacity:1;border-color:rgba(209,213,219,var(--tw-border-opacity));}
								.focus\:border-blue-300:focus{--tw-border-opacity:1;border-color:rgba(147,197,253,var(--tw-border-opacity));}
								.bg-white{--tw-bg-opacity:1;background-color:rgba(255,255,255,var(--tw-bg-opacity));}
								.hover\:bg-gray-300:hover{--tw-bg-opacity:1;background-color:rgba(209,213,219,var(--tw-bg-opacity));}
								.p-0{padding:0;}
								.px-1{padding-left:.25rem;padding-right:.25rem;}
								.px-2{padding-left:.5rem;padding-right:.5rem;}
								.py-1{padding-top:.25rem;padding-bottom:.25rem;}
								.py-2{padding-top:.5rem;padding-bottom:.5rem;}
								.py-4{padding-top:1rem;padding-bottom:1rem;}
								.pt-5{padding-top:1.25rem;}
								.pb-10{padding-bottom:2.5rem;}
								.text-right{text-align:right;}
								.text-sm{font-size:.875rem;line-height:1.25rem;}
								.text-3xl{font-size:1.875rem;line-height:2.25rem;}
								.font-semibold{font-weight:600;}
								.font-extrabold{font-weight:800;}
								.tracking-tight{letter-spacing:-.025em;}
								.text-gray-500{--tw-text-opacity:1;color:rgba(107,114,128,var(--tw-text-opacity));}
								.text-gray-600{--tw-text-opacity:1;color:rgba(75,85,99,var(--tw-text-opacity));}
								.text-gray-700{--tw-text-opacity:1;color:rgba(55,65,81,var(--tw-text-opacity));}
								*,::after,::before{--tw-shadow:0 0 #0000;}
								.focus\:outline-none:focus{outline:2px solid transparent;outline-offset:2px;}
								*,::after,::before{--tw-ring-inset:var(--tw-empty, );--tw-ring-offset-width:0px;--tw-ring-offset-color:#fff;--tw-ring-color:rgba(59, 130, 246, 0.5);--tw-ring-offset-shadow:0 0 #0000;--tw-ring-shadow:0 0 #0000;}
								.focus\:ring:focus{--tw-ring-offset-shadow:var(--tw-ring-inset) 0 0 0 var(--tw-ring-offset-width) var(--tw-ring-offset-color);--tw-ring-shadow:var(--tw-ring-inset) 0 0 0 calc(3px + var(--tw-ring-offset-width)) var(--tw-ring-color);box-shadow:var(--tw-ring-offset-shadow),var(--tw-ring-shadow),var(--tw-shadow,0 0 #0000);}
								.transition{transition-property:background-color,border-color,color,fill,stroke,opacity,box-shadow,transform,filter,-webkit-backdrop-filter;transition-property:background-color,border-color,color,fill,stroke,opacity,box-shadow,transform,filter,backdrop-filter;transition-property:background-color,border-color,color,fill,stroke,opacity,box-shadow,transform,filter,backdrop-filter,-webkit-backdrop-filter;transition-timing-function:cubic-bezier(0.4,0,0.2,1);transition-duration:150ms;}
								.transition-colors{transition-property:background-color,border-color,color,fill,stroke;transition-timing-function:cubic-bezier(0.4,0,0.2,1);transition-duration:150ms;}
								.ease-in-out{transition-timing-function:cubic-bezier(0.4,0,0.2,1);}
								/*! CSS Used from: Embedded */
								*,::after,::before{box-sizing:border-box;}
								body{margin:0;}
								body{font-family:system-ui,-apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif,'Apple Color Emoji','Segoe UI Emoji';}
								table{text-indent:0;border-color:inherit;}
								input{font-family:inherit;font-size:100%;line-height:1.15;margin:0;}
								[type=search]{-webkit-appearance:textfield;outline-offset:-2px;}
								*,::after,::before{box-sizing:border-box;border-width:0;border-style:solid;border-color:currentColor;}
								input::placeholder{opacity:1;color:#9ca3af;}
								table{border-collapse:collapse;}
								a{color:inherit;text-decoration:inherit;}
								input{padding:0;line-height:inherit;color:inherit;}
								svg{display:block;vertical-align:middle;}
								*,::after,::before{--tw-border-opacity:1;border-color:rgba(229,231,235,var(--tw-border-opacity));}
								.container{width:100%;}
								@media (min-width: 640px){
								.container{max-width:640px;}
								}
								@media (min-width: 768px){
								.container{max-width:768px;}
								}
								@media (min-width: 1024px){
								.container{max-width:1024px;}
								}
								.sticky{position:sticky;}
								.file-icon {
								content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' aria-hidden='true' focusable='false' data-prefix='fas' data-icon='file' class='svg-inline--fa fa-file fa-w-12' role='img' viewBox='0 0 384 512'%3E%3Cpath fill='currentColor' d='M224 136V0H24C10.7 0 0 10.7 0 24v464c0 13.3 10.7 24 24 24h336c13.3 0 24-10.7 24-24V160H248c-13.2 0-24-10.8-24-24zm160-14.1v6.1H256V0h6.1c6.4 0 12.5 2.5 17 7l97.9 98c4.5 4.5 7 10.6 7 16.9z'/%3E%3C/svg%3E");
								}
						</style>
					</head>
					<body class="container mx-auto">
						<div class="flex justify-between pb-10 pt-5">
							<div class="text-3xl font-extrabold text-gray-700 tracking-tight">
								<xsl:value-of select="$hostname" />
							</div>
							<input
								type="search"
								id="search-box"
								oninput="handleSearch()"
								placeholder="filter results"
								class="transition focus:outline-none focus:ring focus:border-blue-300 border border-gray-300 px-2 py-1"
								/>
						</div>
						<div class="list">
							<table summary="Directory Listing" class="w-full table-auto border-collapse">
								<thead>
									<tr class="z-20 sticky text-sm font-semibold text-gray-600 bg-white p-0">
										<td></td>
										<td class="">Name</td>
										<td class="">Last Modified</td>
										<td class="text-right">Size</td>
										<td class="text-right">Type</td>
									</tr>
								</thead>
								<!-- uncomment the following block to enable totals -->
								<tfoot>
									<tr>
										<!-- five cols -->
										<td>&nbsp;</td>
										<td>&nbsp;</td>
										<td>&nbsp;</td>
										<td>&nbsp;</td>
										<td>&nbsp;</td>
									</tr>
								</tfoot>
								<tbody>
									<tr class="border-b">
										<td class="px-1 py-2 icon"></td>
										<td class="px-1 py-2">
											<a href="../"><svg xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false" data-prefix="fas" data-icon="level-up-alt" style="height: 16px" class="svg-inline--fa fa-level-up-alt fa-w-10" role="img" viewBox="0 0 320 512"><path fill="currentColor" d="M313.553 119.669L209.587 7.666c-9.485-10.214-25.676-10.229-35.174 0L70.438 119.669C56.232 134.969 67.062 160 88.025 160H152v272H68.024a11.996 11.996 0 0 0-8.485 3.515l-56 56C-4.021 499.074 1.333 512 12.024 512H208c13.255 0 24-10.745 24-24V160h63.966c20.878 0 31.851-24.969 17.587-40.331z"/></svg></a>
										</td>
										<td class="px-1 py-2"></td>
										<td class="px-1 py-2 text-right"></td>
										<td class="px-1 py-2 text-right"></td>
									</tr>
									<xsl:apply-templates />
								</tbody>
							</table>
						</div>
						<div class="flex justify-between py-4 text-sm text-gray-500">
						<div>
							<xsl:value-of select="count(//directory)"/> Directories, <xsl:value-of select="count(//file)"/> Files, <xsl:call-template name="size"> <xsl:with-param name="bytes" select="sum(//file/@size)" /> </xsl:call-template> Total
						</div>
						<div class="foot">powered by Nginx</div>
						<script>
								document.querySelector("#search-box").style.display = '';
								if (window.location.hash)
								{
									document.querySelector("#search-box").value = window.location.hash.split('#')[1];
									handleSearch()
								}

								function handleSearch() {
									const input = document.querySelector("#search-box");
									window.location.hash = input.value;
									const filter = input.value.toUpperCase();
									const table = document.querySelector("table");
									const trGroup = [...table.querySelectorAll("tr")].splice(3);

									trGroup.forEach(tr => {
										td = tr.querySelector("td:nth-child(2)");

										if (td) {
											const tdContent = td.textContent || td.innerText;

											if (tdContent.toUpperCase().includes(filter)) {
												tr.style.display = "";
											} else {
												tr.style.display = "none";
											}
										}
									})
								}
						</script>
					</div>
					</body>
				</html>
			</xsl:template>
		</xsl:stylesheet>
