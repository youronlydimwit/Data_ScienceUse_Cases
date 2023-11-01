Attribute VB_Name = "Module5"
Function SimilarityNGramJaccard(s1 As String, s2 As String, n As Integer) As Double
    Dim set1 As Object
    Set set1 = CreateObject("Scripting.Dictionary")
    
    Dim set2 As Object
    Set set2 = CreateObject("Scripting.Dictionary")
    
    Dim i As Integer
    Dim ngram1 As String
    Dim ngram2 As String
    
    ' Create n-grams from string 1
    For i = 1 To Len(s1) - n + 1
        ngram1 = Mid(s1, i, n)
        set1(ngram1) = 1
    Next i
    
    ' Create n-grams from string 2
    For i = 1 To Len(s2) - n + 1
        ngram2 = Mid(s2, i, n)
        set2(ngram2) = 1
    Next i
    
    ' Calculate the size of the intersection of the n-gram sets
    Dim intersectionSize As Integer
    intersectionSize = 0
    
    For Each Key In set1.Keys
        If set2.Exists(Key) Then
            intersectionSize = intersectionSize + 1
        End If
    Next Key
    
    ' Calculate the n-gram similarity
    Dim similarity As Double
    
    If set1.Count + set2.Count = 0 Then
        similarity = 1
    Else
        similarity = intersectionSize / (set1.Count + set2.Count - intersectionSize)
    End If
    
    SimilarityNGramJaccard = similarity
End Function
