Attribute VB_Name = "Module1"
Function SimilarityLevenshtein(target As String, reference As String) As Double
    Dim maxLen As Long
    Dim minLen As Long
    Dim distance As Double
    Dim similarity As Double

    ' Remove spaces and convert to lowercase
    target = Replace(LCase(target), " ", "")
    reference = Replace(LCase(reference), " ", "")

    maxLen = IIf(Len(target) > Len(reference), Len(target), Len(reference))
    minLen = IIf(Len(target) < Len(reference), Len(target), Len(reference))

    distance = maxLen - minLen
    For i = 1 To minLen
        If Mid(target, i, 1) <> Mid(reference, i, 1) Then
            distance = distance + 1
        End If
    Next i

    similarity = (1 - distance / maxLen)
    SimilarityLevenshtein = similarity
End Function

