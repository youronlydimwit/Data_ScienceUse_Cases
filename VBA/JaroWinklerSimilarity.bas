Attribute VB_Name = "Module2"
Function SimilarityJaroWinkler(s1 As String, s2 As String) As Double
    Dim m As Integer ' Number of matching characters
    Dim t As Integer ' Number of transpositions
    Dim l1 As Integer ' Length of string 1
    Dim l2 As Integer ' Length of string 2
    Dim maxLen As Integer
    Dim prefix As Integer
    Dim jw As Double ' Jaro-Winkler similarity

    l1 = Len(s1)
    l2 = Len(s2)
    maxLen = IIf(l1 > l2, l1, l2)

    ' Calculate the number of matching characters
    m = 0
    t = 0
    For i = 1 To l1
        For j = IIf(i - 2 > 0, i - 2, 1) To IIf(i + 2 <= l2, i + 2, l2)
            If Mid(s1, i, 1) = Mid(s2, j, 1) Then
                m = m + 1
                If i <> j Then t = t + 1
                Exit For
            End If
        Next j
    Next i

    ' Calculate the prefix length
    prefix = 0
    For i = 1 To IIf(l1 > 4, 4, l1)
        If Mid(s1, i, 1) = Mid(s2, i, 1) Then
            prefix = prefix + 1
        Else
            Exit For
        End If
    Next i

    ' Calculate the Jaro similarity
    If m = 0 Then
        jw = 0
    Else
        jw = (m / l1 + m / l2 + (m - t) / m) / 3
        jw = jw + (prefix * 0.1 * (1 - jw))
    End If

    SimilarityJaroWinkler = jw
End Function
