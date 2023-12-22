function labels = organizationSensitivities()
% @brief Organisation sensitivity labels
%
% Return a structure whose fields define sensitivity labels used
% by an organization.
% The outer structure field names can be chosen at will (avoid spaces and
% other special characters though).
% The inner structure field names should inculde:
%   - **AssignmentMethod** 
%   - **LabelId** UUID of the label (to be obtained from organization
% or by retro-engineering existing Excel files)
%   - **LabelName** Internal name of the label (to be obtained from organization
% or by retro-engineering existing Excel files)
%   - **ContentBits** Bit-field defining label properties (to be obtained from organization
% or by retro-engineering existing Excel files)
%
% The fields correspond to the members of 
% <a href="https://learn.microsoft.com/fr-fr/office/vba/api/overview/library-reference/sensitivitylabel-members-office">Office.SensitivityLabel</a>.
%
% @return A structure whose fields define sensitivity labels used
% by an organization (see above).

    labels = struct(                                                ...
        'Public', struct(                                           ...
            'AssignmentMethod', 'PRIVILEGED',                       ...
            'LabelId', [LABEL_UUID],                                ...
            'LabelName', [LABEL_NAME],                              ...
            'ContentBits', [ENCRYPT | FILIGRANE | CONTENT_FOOTER]   ... CONTENT_FOOTER
        ),                                                          ...
        'General', struct(                                          ...
            'AssignmentMethod', 'PRIVILEGED',                       ...
            'LabelId', '57443d00-af18-408c-9335-47b5de3ec9b9',      ...
            'LabelName', 'General v2',                              ...
            'ContentBits', [ENCRYPT | FILIGRANE | CONTENT_FOOTER]   ... CONTENT_FOOTER
        )                                                           ...
    );
end