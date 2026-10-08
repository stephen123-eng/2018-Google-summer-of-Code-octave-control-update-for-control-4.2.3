function editarchitecture()
  graphics_toolkit qt

  global fig4 h4

  % Guarantee h4 exists as a valid structure BEFORE setting any fields
  if !isstruct(h4)
    h4 = struct();
  endif

  % Ensure fig4 exists and set as current figure
  if isempty(fig4) || ~ishandle(fig4)
    fig4 = figure(4, "Name", "Edit Architecture", "NumberTitle", "off", "menubar", "none", "Visible", "off");
  endif

  set(0, 'currentfigure', fig4);
  clf(fig4);

  set(fig4, 'resize', 'off');

  % -------------------------------------------------------------------
  % 1. Create Layout Axes First
  % -------------------------------------------------------------------
  h4.ax7 = axes(); set(h4.ax7, "position", [0.25 0.35 0.75 0.8]);
  h4.ax6 = axes(); set(h4.ax6, "position", [0.05 0.10 0.2 0.1]);
  h4.ax5 = axes(); set(h4.ax5, "position", [0.05 0.25 0.2 0.1]);
  h4.ax4 = axes(); set(h4.ax4, "position", [0.05 0.40 0.2 0.1]);
  h4.ax3 = axes(); set(h4.ax3, "position", [0.05 0.55 0.2 0.1]);
  h4.ax2 = axes(); set(h4.ax2, "position", [0.05 0.70 0.2 0.1]);
  h4.ax1 = axes(); set(h4.ax1, "position", [0.05 0.85 0.2 0.1]);

  % -------------------------------------------------------------------
  % 2. Image Loading
  % -------------------------------------------------------------------
  pkg_dir = fileparts(mfilename('fullpath'));
  img_dir = fullfile(pkg_dir, 'images');

  sisoconfig = cell(1, 6);
  for i = 1:6
    thumb_path = fullfile(img_dir, sprintf('SISOConfig%dThumb.png', i));
    if exist(thumb_path, 'file')
      sisoconfig{i} = im2double(imread(thumb_path));
    else
      sisoconfig{i} = zeros(100, 100, 3);
    endif
  endfor

  for i = 1:6
    config_path = fullfile(img_dir, sprintf('Config%d.png', i));
    field_name = sprintf('sisoCONFIG%d', i);
    if exist(config_path, 'file')
      h4.img.(field_name) = im2double(imread(config_path));
    else
      h4.img.(field_name) = zeros(300, 400, 3);
    endif
  endfor

  axes(h4.ax1); image(sisoconfig{1}); axis off; axis image;
  axes(h4.ax2); image(sisoconfig{2}); axis off; axis image;
  axes(h4.ax3); image(sisoconfig{3}); axis off; axis image;
  axes(h4.ax4); image(sisoconfig{4}); axis off; axis image;
  axes(h4.ax5); image(sisoconfig{5}); axis off; axis image;
  axes(h4.ax6); image(sisoconfig{6}); axis off; axis image;

  if isfield(h4, 'img') && isfield(h4.img, 'sisoCONFIG1')
    axes(h4.ax7); image(h4.img.sisoCONFIG1); axis off; axis image;
  endif

  % -------------------------------------------------------------------
  % 3. Create Block Table Panels, Identifiers & Edit Fields FIRST
  % -------------------------------------------------------------------
  p4 = uipanel("Parent", fig4, "title", "Blocks", "position", [.25 .1 .75 .45]);
  gp2 = uibuttongroup("Parent", p4, "Position", [0 0.8 1 0.2]);

  h4.gp2_title1 = uicontrol(gp2, "style", "text", "units", "normalized", "fontweight", "bold", "string", "Identifier", "horizontalalignment", "left", "position", [0 0 0.18 1]);
  h4.gp2_title2 = uicontrol(gp2, "style", "text", "units", "normalized", "fontweight", "bold", "string", "Block Name", "horizontalalignment", "left", "position", [0.18 0 0.21 1]);
  h4.gp2_title3 = uicontrol(gp2, "style", "text", "units", "normalized", "fontweight", "bold", "string", "Value", "horizontalalignment", "left", "position", [0.42 0 0.2 1]);

  gp3 = uibuttongroup("Parent", p4, "Position", [0 0 1 0.8]);

  % Identifiers
  h4.gp3_identifier1 = uicontrol(gp3, "style", "text", "units", "normalized", "string", "F", "horizontalalignment", "left", "position", [0.05 0.9 0.04 .1]);
  h4.gp3_identifier2 = uicontrol(gp3, "style", "text", "units", "normalized", "string", "C", "horizontalalignment", "left", "position", [0.05 0.75 0.04 .1]);
  h4.gp3_identifier3 = uicontrol(gp3, "style", "text", "units", "normalized", "string", "G", "horizontalalignment", "left", "position", [0.05 0.60 0.04 .1]);
  h4.gp3_identifier4 = uicontrol(gp3, "style", "text", "units", "normalized", "string", "H", "horizontalalignment", "left", "position", [0.05 0.45 0.04 .1]);
  h4.gp3_identifier5 = uicontrol(gp3, "style", "text", "units", "normalized", "string", "", "horizontalalignment", "left", "position", [0.05 0.30 0.04 .1]);
  h4.gp3_identifier6 = uicontrol(gp3, "style", "text", "units", "normalized", "string", "", "horizontalalignment", "left", "position", [0.05 0.15 0.04 .1]);
  h4.gp3_identifier7 = uicontrol(gp3, "style", "text", "units", "normalized", "string", "", "horizontalalignment", "left", "position", [0.05 0.0 0.04 .1]);

  % Block Name Edit Fields
  h4.gp3_identifier1_edit = uicontrol(gp3, "style", "edit", "units", "normalized", "string", "F", "horizontalalignment", "center", "position", [0.18 0.9 0.2 .1], 'backgroundcolor', 'white');
  h4.gp3_identifier2_edit = uicontrol(gp3, "style", "edit", "units", "normalized", "string", "C", "horizontalalignment", "center", "position", [0.18 0.75 0.2 .1], 'backgroundcolor', 'white');
  h4.gp3_identifier3_edit = uicontrol(gp3, "style", "edit", "units", "normalized", "string", "G", "horizontalalignment", "center", "position", [0.18 0.60 0.2 .1], 'backgroundcolor', 'white');
  h4.gp3_identifier4_edit = uicontrol(gp3, "style", "edit", "units", "normalized", "string", "H", "horizontalalignment", "center", "position", [0.18 0.45 0.2 .1], 'backgroundcolor', 'white');
  h4.gp3_identifier5_edit = uicontrol(gp3, "style", "edit", "units", "normalized", "string", "--", "horizontalalignment", "center", "position", [0.18 0.30 0.2 .1], 'backgroundcolor', 'white');
  h4.gp3_identifier6_edit = uicontrol(gp3, "style", "edit", "units", "normalized", "string", "--", "horizontalalignment", "center", "position", [0.18 0.15 0.2 .1], 'backgroundcolor', 'white');
  h4.gp3_identifier7_edit = uicontrol(gp3, "style", "edit", "units", "normalized", "string", "--", "horizontalalignment", "center", "position", [0.18 0.0 0.2 .1], 'backgroundcolor', 'white');

  % Value Edit Fields
  h4.gp3_identifier1_edit2 = uicontrol(gp3, "style", "edit", "units", "normalized", "string", "<1x1 zpk>", "horizontalalignment", "center", "position", [0.42 0.9 0.2 .1], 'backgroundcolor', 'white');
  h4.gp3_identifier2_edit2 = uicontrol(gp3, "style", "edit", "units", "normalized", "string", "<1x1 zpk>", "horizontalalignment", "center", "position", [0.42 0.75 0.2 .1], 'backgroundcolor', 'white');
  h4.gp3_identifier3_edit2 = uicontrol(gp3, "style", "edit", "units", "normalized", "string", "<1x1 zpk>", "horizontalalignment", "center", "position", [0.42 0.60 0.2 .1], 'backgroundcolor', 'white');
  h4.gp3_identifier4_edit2 = uicontrol(gp3, "style", "edit", "units", "normalized", "string", "<1x1 zpk>", "horizontalalignment", "center", "position", [0.42 0.45 0.2 .1], 'backgroundcolor', 'white');
  h4.gp3_identifier5_edit2 = uicontrol(gp3, "style", "edit", "units", "normalized", "string", "--", "horizontalalignment", "center", "position", [0.42 0.30 0.2 .1], 'backgroundcolor', 'white');
  h4.gp3_identifier6_edit2 = uicontrol(gp3, "style", "edit", "units", "normalized", "string", "--", "horizontalalignment", "center", "position", [0.42 0.15 0.2 .1], 'backgroundcolor', 'white');
  h4.gp3_identifier7_edit2 = uicontrol(gp3, "style", "edit", "units", "normalized", "string", "--", "horizontalalignment", "center", "position", [0.42 0.0 0.2 .1], 'backgroundcolor', 'white');

  % Action buttons
  h4.btn_ok = uicontrol("Parent", fig4, "style", "pushbutton", "units", "normalized", "string", "OK", "position", [0.66 0.01 0.1 0.06], 'callback', @call_ok);
  h4.btn_cancel = uicontrol("Parent", fig4, "style", "pushbutton", "units", "normalized", "string", "Cancel", "position", [0.78 0.01 0.1 0.06], 'callback', @call_cancell);
  h4.btn_help = uicontrol("Parent", fig4, "style", "pushbutton", "units", "normalized", "string", "Help", "position", [0.9 0.01 0.1 0.06], 'callback', @call_help);

  % -------------------------------------------------------------------
  % 4. Instantiate Radio Buttons LAST
  % -------------------------------------------------------------------
  gp = uibuttongroup("Parent", fig4, "Position", [0 0 0.05 1]);

  h4.b6 = uicontrol(gp, "style", "radiobutton", "units", "normalized", "Position", [0.25 0.10 0.75 0.1], 'callback', @edit_architecture_cb);
  h4.b5 = uicontrol(gp, "style", "radiobutton", "units", "normalized", "Position", [0.25 0.25 0.75 0.1], 'callback', @edit_architecture_cb);
  h4.b4 = uicontrol(gp, "style", "radiobutton", "units", "normalized", "Position", [0.25 0.40 0.75 0.1], 'callback', @edit_architecture_cb);
  h4.b3 = uicontrol(gp, "style", "radiobutton", "units", "normalized", "Position", [0.25 0.55 0.75 0.1], 'callback', @edit_architecture_cb);
  h4.b2 = uicontrol(gp, "style", "radiobutton", "units", "normalized", "Position", [0.25 0.70 0.75 0.1], 'callback', @edit_architecture_cb);
  h4.b1 = uicontrol(gp, "style", "radiobutton", "units", "normalized", "Position", [0.25 0.85 0.75 0.1], 'callback', @edit_architecture_cb);

  set(fig4, "color", get(0, "defaultuicontrolbackgroundcolor"));
  set(fig4, 'CloseRequestFcn', @visibleoff_architecture);

  % Safely set initial value without triggering callback recursion
  set(h4.b1, 'callback', []);
  set(h4.b1, 'value', 1);
  set(h4.b1, 'callback', @edit_architecture_cb);
  h4.set_arch = 1;

endfunction

% -------------------------------------------------------------------
% Sub-functions
% -------------------------------------------------------------------
function edit_architecture_cb(src, evt)
  global h4

  if !isstruct(h4) || !isfield(h4, 'b1') || !ishandle(h4.b1) || ...
     !isfield(h4, 'gp3_identifier1') || !ishandle(h4.gp3_identifier1) || ...
     !isfield(h4, 'ax7') || !ishandle(h4.ax7)
    return;
  endif

  if get(h4.b1, 'value') && isfield(h4.img, 'sisoCONFIG1')
    axes(h4.ax7);  image(h4.img.sisoCONFIG1); axis off; axis image;
    set(h4.gp3_identifier1, 'String', 'F'); set(h4.gp3_identifier2, 'String', 'C'); set(h4.gp3_identifier3, 'String', 'G'); set(h4.gp3_identifier4, 'String', 'H'); set(h4.gp3_identifier5, 'String', '--'); set(h4.gp3_identifier6, 'String', '--'); set(h4.gp3_identifier7, 'String', '--');
    set(h4.gp3_identifier1_edit, 'String', 'F'); set(h4.gp3_identifier2_edit, 'String', 'C'); set(h4.gp3_identifier3_edit, 'String', 'G'); set(h4.gp3_identifier4_edit, 'String', 'H'); set(h4.gp3_identifier5_edit, 'String', '--'); set(h4.gp3_identifier6_edit, 'String', '--'); set(h4.gp3_identifier7_edit, 'String', '--');
    set(h4.gp3_identifier1_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier2_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier3_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier4_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier5_edit2, 'String', '--'); set(h4.gp3_identifier6_edit2, 'String', '--'); set(h4.gp3_identifier7_edit2, 'String', '--');
    h4.set_arch = 1;
  elseif get(h4.b2, 'value') && isfield(h4.img, 'sisoCONFIG2')
    axes(h4.ax7);  image(h4.img.sisoCONFIG2); axis off; axis image;
    set(h4.gp3_identifier1, 'String', 'F'); set(h4.gp3_identifier2, 'String', 'C'); set(h4.gp3_identifier3, 'String', 'G'); set(h4.gp3_identifier4, 'String', 'H'); set(h4.gp3_identifier5, 'String', '--'); set(h4.gp3_identifier6, 'String', '--'); set(h4.gp3_identifier7, 'String', '--');
    set(h4.gp3_identifier1_edit, 'String', 'F'); set(h4.gp3_identifier2_edit, 'String', 'C'); set(h4.gp3_identifier3_edit, 'String', 'G'); set(h4.gp3_identifier4_edit, 'String', 'H'); set(h4.gp3_identifier5_edit, 'String', '--'); set(h4.gp3_identifier6_edit, 'String', '--'); set(h4.gp3_identifier7_edit, 'String', '--');
    set(h4.gp3_identifier1_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier2_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier3_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier4_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier5_edit2, 'String', '--'); set(h4.gp3_identifier6_edit2, 'String', '--'); set(h4.gp3_identifier7_edit2, 'String', '--');
    h4.set_arch = 2;
  elseif get(h4.b3, 'value') && isfield(h4.img, 'sisoCONFIG3')
    axes(h4.ax7);  image(h4.img.sisoCONFIG3); axis off; axis image;
    set(h4.gp3_identifier1, 'String', 'F'); set(h4.gp3_identifier2, 'String', 'C'); set(h4.gp3_identifier3, 'String', 'G'); set(h4.gp3_identifier4, 'String', 'H'); set(h4.gp3_identifier5, 'String', '--'); set(h4.gp3_identifier6, 'String', '--'); set(h4.gp3_identifier7, 'String', '--');
    set(h4.gp3_identifier1_edit, 'String', 'F'); set(h4.gp3_identifier2_edit, 'String', 'C'); set(h4.gp3_identifier3_edit, 'String', 'G'); set(h4.gp3_identifier4_edit, 'String', 'H'); set(h4.gp3_identifier5_edit, 'String', '--'); set(h4.gp3_identifier6_edit, 'String', '--'); set(h4.gp3_identifier7_edit, 'String', '--');
    set(h4.gp3_identifier1_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier2_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier3_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier4_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier5_edit2, 'String', '--'); set(h4.gp3_identifier6_edit2, 'String', '--'); set(h4.gp3_identifier7_edit2, 'String', '--');
    h4.set_arch = 3;
  elseif get(h4.b4, 'value') && isfield(h4.img, 'sisoCONFIG4')
    axes(h4.ax7);  image(h4.img.sisoCONFIG4); axis off; axis image;
    set(h4.gp3_identifier1, 'String', 'C1'); set(h4.gp3_identifier2, 'String', 'C2'); set(h4.gp3_identifier3, 'String', 'G'); set(h4.gp3_identifier4, 'String', 'H'); set(h4.gp3_identifier5, 'String', '--'); set(h4.gp3_identifier6, 'String', '--'); set(h4.gp3_identifier7, 'String', '--');
    set(h4.gp3_identifier1_edit, 'String', 'C1'); set(h4.gp3_identifier2_edit, 'String', 'C2'); set(h4.gp3_identifier3_edit, 'String', 'G'); set(h4.gp3_identifier4_edit, 'String', 'H'); set(h4.gp3_identifier5_edit, 'String', '--'); set(h4.gp3_identifier6_edit, 'String', '--'); set(h4.gp3_identifier7_edit, 'String', '--');
    set(h4.gp3_identifier1_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier2_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier3_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier4_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier5_edit2, 'String', '--'); set(h4.gp3_identifier6_edit2, 'String', '--'); set(h4.gp3_identifier7_edit2, 'String', '--');
    h4.set_arch = 4;
  elseif get(h4.b5, 'value') && isfield(h4.img, 'sisoCONFIG5')
    axes(h4.ax7);  image(h4.img.sisoCONFIG5); axis off; axis image;
    set(h4.gp3_identifier1, 'String', 'F'); set(h4.gp3_identifier2, 'String', 'C'); set(h4.gp3_identifier3, 'String', 'G1'); set(h4.gp3_identifier4, 'String', 'G2'); set(h4.gp3_identifier5, 'String', 'Gd'); set(h4.gp3_identifier6, 'String', '--'); set(h4.gp3_identifier7, 'String', '--');
    set(h4.gp3_identifier1_edit, 'String', 'F'); set(h4.gp3_identifier2_edit, 'String', 'C'); set(h4.gp3_identifier3_edit, 'String', 'G1'); set(h4.gp3_identifier4_edit, 'String', 'G2'); set(h4.gp3_identifier5_edit, 'String', 'Gd'); set(h4.gp3_identifier6_edit, 'String', '--'); set(h4.gp3_identifier7_edit, 'String', '--');
    set(h4.gp3_identifier1_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier2_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier3_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier4_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier5_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier6_edit2, 'String', ''); set(h4.gp3_identifier7_edit2, 'String', '--');
    h4.set_arch = 5;
  elseif get(h4.b6, 'value') && isfield(h4.img, 'sisoCONFIG6')
    axes(h4.ax7);  image(h4.img.sisoCONFIG6); axis off; axis image;
    set(h4.gp3_identifier1, 'String', 'F'); set(h4.gp3_identifier2, 'String', 'C1'); set(h4.gp3_identifier3, 'String', 'C2'); set(h4.gp3_identifier4, 'String', 'G1'); set(h4.gp3_identifier5, 'String', 'G2'); set(h4.gp3_identifier6, 'String', 'H1'); set(h4.gp3_identifier7, 'String', 'H2');
    set(h4.gp3_identifier1_edit, 'String', 'F'); set(h4.gp3_identifier2_edit, 'String', 'C1'); set(h4.gp3_identifier3_edit, 'String', 'C2'); set(h4.gp3_identifier4_edit, 'String', 'G1'); set(h4.gp3_identifier5_edit, 'String', 'G2'); set(h4.gp3_identifier6_edit, 'String', 'H1'); set(h4.gp3_identifier7_edit, 'String', 'H2');
    set(h4.gp3_identifier1_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier2_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier3_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier4_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier5_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier6_edit2, 'String', '<1x1 zpk>'); set(h4.gp3_identifier7_edit2, 'String', '<1x1 zpk>');
    h4.set_arch = 6;
  endif
endfunction

function visibleoff_architecture(src, evt)
  global fig4
  if ishandle(fig4)
    set(fig4, 'Visible', 'off');
  endif
endfunction

function call_ok(src, evt)
endfunction

function call_cancell(src, evt)
  global fig4
  str1 = questdlg('Are you sure you want to leave this page without save?');
  if strcmp(str1, "Yes") && ishandle(fig4)
    set(fig4, 'Visible', 'off');
  endif
endfunction

function call_help(src, evt)
  helpdlg('Access the following website for more information: https://eriveltongualter.github.io/GSoC2018/pages/documentation.html', 'Help');
endfunction
